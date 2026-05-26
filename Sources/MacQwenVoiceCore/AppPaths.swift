import Foundation

public struct AppPaths: Sendable {
    public let root: URL
    public let models: URL
    public let sharedModels: URL
    public let projects: URL
    public let outputs: URL
    public let references: URL
    public let clonePrompts: URL
    public let cache: URL
    public let logs: URL
    public let config: URL
    public let deepSeekConfig: URL
    public let databaseDirectory: URL
    public let database: URL

    public init(root: URL = AppPaths.defaultRoot()) {
        self.root = root
        self.models = root.appendingPathComponent("models", isDirectory: true)
        self.sharedModels = models.appendingPathComponent("shared", isDirectory: true)
        self.projects = root.appendingPathComponent("projects", isDirectory: true)
        self.outputs = root.appendingPathComponent("outputs", isDirectory: true)
        self.references = root.appendingPathComponent("references", isDirectory: true)
        self.clonePrompts = root.appendingPathComponent("clone_prompts", isDirectory: true)
        self.cache = root.appendingPathComponent("cache", isDirectory: true)
        self.logs = root.appendingPathComponent("logs", isDirectory: true)
        self.config = root.appendingPathComponent("config", isDirectory: true)
        self.deepSeekConfig = config.appendingPathComponent("deepseek.json")
        self.databaseDirectory = root.appendingPathComponent("database", isDirectory: true)
        self.database = databaseDirectory.appendingPathComponent("MacQwenVoice.sqlite")
    }

    public func ensureDirectories() throws {
        let manager = FileManager.default
        for url in [root, models, sharedModels, projects, outputs, references, clonePrompts, cache, logs, config, databaseDirectory] {
            try manager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    public func modelDirectory(for spec: QwenModelSpec) -> URL {
        models.appendingPathComponent(spec.repository.replacingOccurrences(of: "/", with: "__"), isDirectory: true)
    }

    public static func defaultRoot(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        homeDirectory
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("VoiceStudio", isDirectory: true)
            .appendingPathComponent("Workspace", isDirectory: true)
    }

    public static func legacyDocumentsWorkspaceRoots(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        let documents = homeDirectory.appendingPathComponent("Documents", isDirectory: true)
        return [
            documents.appendingPathComponent("MacQwenVoice Workspace", isDirectory: true),
            documents
                .appendingPathComponent("MacQwenVoice", isDirectory: true)
                .appendingPathComponent("Workspace", isDirectory: true)
        ]
    }

    public static func legacyApplicationSupportRoot(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        homeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("MacQwenVoice", isDirectory: true)
    }
}
