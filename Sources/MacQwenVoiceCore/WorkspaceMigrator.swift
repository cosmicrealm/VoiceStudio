import Foundation

public struct WorkspaceMigrationResult: Equatable, Sendable {
    public let didMigrate: Bool
    public let migratedItems: [String]

    public init(didMigrate: Bool, migratedItems: [String]) {
        self.didMigrate = didMigrate
        self.migratedItems = migratedItems
    }
}

public enum WorkspaceMigrator {
    public static func relocateWorkspaceIfNeeded(
        from legacyRoots: [URL],
        to targetRoot: URL = AppPaths.defaultRoot(),
        catalog: ModelCatalog = .default,
        fileManager: FileManager = .default
    ) throws -> WorkspaceMigrationResult {
        let targetPaths = AppPaths(root: targetRoot)
        let normalizedTarget = targetRoot.standardizedFileURL.path
        let existingLegacyRoots = legacyRoots.filter { legacyRoot in
            legacyRoot.standardizedFileURL.path != normalizedTarget && fileManager.fileExists(atPath: legacyRoot.path)
        }
        guard !existingLegacyRoots.isEmpty else {
            try targetPaths.ensureDirectories()
            return WorkspaceMigrationResult(didMigrate: false, migratedItems: [])
        }

        if !hasWorkspaceContent(at: targetRoot, fileManager: fileManager) {
            for legacyRoot in existingLegacyRoots {
                do {
                    let result = try migrateIfNeeded(from: legacyRoot, to: targetRoot, catalog: catalog, fileManager: fileManager)
                    if result.didMigrate {
                        return WorkspaceMigrationResult(didMigrate: true, migratedItems: ["workspace"])
                    }
                } catch {
                    continue
                }
            }
        }

        var migrated: [String] = []
        for legacyRoot in existingLegacyRoots {
            let result = try migrateIfNeeded(from: legacyRoot, to: targetRoot, catalog: catalog, fileManager: fileManager)
            migrated.append(contentsOf: result.migratedItems)
        }
        return WorkspaceMigrationResult(didMigrate: !migrated.isEmpty, migratedItems: Array(Set(migrated)).sorted())
    }

    public static func migrateIfNeeded(
        from legacyRoot: URL = AppPaths.legacyApplicationSupportRoot(),
        to targetRoot: URL = AppPaths.defaultRoot(),
        catalog: ModelCatalog = .default,
        fileManager: FileManager = .default
    ) throws -> WorkspaceMigrationResult {
        guard fileManager.fileExists(atPath: legacyRoot.path) else {
            try AppPaths(root: targetRoot).ensureDirectories()
            return WorkspaceMigrationResult(didMigrate: false, migratedItems: [])
        }

        let targetPaths = AppPaths(root: targetRoot)
        try targetPaths.ensureDirectories()
        var migrated: [String] = []

        for directoryName in ["models", "projects", "outputs", "references", "clone_prompts", "cache", "logs", "config"] {
            let source = legacyRoot.appendingPathComponent(directoryName, isDirectory: true)
            let target = targetRoot.appendingPathComponent(directoryName, isDirectory: true)
            if try copyDirectoryContentsIfNeeded(from: source, to: target, fileManager: fileManager) {
                migrated.append(directoryName)
            }
        }

        if try copyFirstExistingFile(
            sources: [
                legacyRoot.appendingPathComponent("MacQwenVoice.sqlite"),
                legacyRoot.appendingPathComponent("database/MacQwenVoice.sqlite")
            ],
            target: targetPaths.database,
            fileManager: fileManager
        ) {
            migrated.append("database/MacQwenVoice.sqlite")
        }

        if try copyFirstExistingFile(
            sources: [
                legacyRoot.appendingPathComponent("backend.sqlite"),
                legacyRoot.appendingPathComponent("database/backend.sqlite")
            ],
            target: targetPaths.databaseDirectory.appendingPathComponent("backend.sqlite"),
            fileManager: fileManager
        ) {
            migrated.append("database/backend.sqlite")
        }

        if !migrated.isEmpty, fileManager.fileExists(atPath: targetPaths.database.path) {
            try rewriteDatabasePaths(
                databasePath: targetPaths.database.path,
                legacyRoot: legacyRoot,
                targetPaths: targetPaths,
                catalog: catalog
            )
        }
        return WorkspaceMigrationResult(didMigrate: !migrated.isEmpty, migratedItems: migrated)
    }

    private static func hasWorkspaceContent(at root: URL, fileManager: FileManager) -> Bool {
        guard fileManager.fileExists(atPath: root.path) else { return false }
        return ((try? fileManager.contentsOfDirectory(atPath: root.path)) ?? []).isEmpty == false
    }

    private static func copyDirectoryContentsIfNeeded(
        from source: URL,
        to target: URL,
        fileManager: FileManager
    ) throws -> Bool {
        guard fileManager.fileExists(atPath: source.path) else { return false }
        try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
        let children = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        var copied = false
        for child in children {
            let destination = target.appendingPathComponent(child.lastPathComponent, isDirectory: child.hasDirectoryPath)
            if !fileManager.fileExists(atPath: destination.path) {
                try fileManager.copyItem(at: child, to: destination)
                copied = true
            }
        }
        return copied
    }

    private static func copyFirstExistingFile(
        sources: [URL],
        target: URL,
        fileManager: FileManager
    ) throws -> Bool {
        guard !fileManager.fileExists(atPath: target.path) else { return false }
        guard let source = sources.first(where: { fileManager.fileExists(atPath: $0.path) }) else { return false }
        try fileManager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: source, to: target)
        return true
    }

    private static func rewriteDatabasePaths(
        databasePath: String,
        legacyRoot: URL,
        targetPaths: AppPaths,
        catalog: ModelCatalog
    ) throws {
        let database = try AppDatabase(path: databasePath)
        try database.rewritePathPrefix(from: legacyRoot.path, to: targetPaths.root.path)
        for state in try database.listModelStates() {
            guard let spec = catalog.models.first(where: { $0.id == state.id }) else { continue }
            let existingPath = state.localPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let nextPath: String
            if existingPath.isEmpty {
                nextPath = targetPaths.modelDirectory(for: spec).path
            } else if existingPath == legacyRoot.path || existingPath.hasPrefix("\(legacyRoot.path)/") {
                nextPath = existingPath.replacingOccurrences(of: legacyRoot.path, with: targetPaths.root.path)
            } else {
                continue
            }
            if state.localPath != nextPath {
                try database.saveModelState(
                    ModelState(
                        id: state.id,
                        localPath: nextPath,
                        status: state.status,
                        bytes: state.bytes
                    )
                )
            }
        }
    }
}
