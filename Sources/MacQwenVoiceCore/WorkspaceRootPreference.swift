import Foundation

public enum WorkspaceRootPreference {
    private static let key = "VoiceStudio.workspaceRootPath"

    public static func load(
        defaults: UserDefaults = .standard,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL {
        let saved = defaults.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !saved.isEmpty {
            let savedURL = URL(fileURLWithPath: saved, isDirectory: true).standardizedFileURL
            if isDefaultRoot(savedURL, homeDirectory: homeDirectory) {
                return AppPaths.defaultRoot(homeDirectory: homeDirectory).standardizedFileURL
            }
            return savedURL
        }
        return AppPaths.defaultRoot(homeDirectory: homeDirectory).standardizedFileURL
    }

    public static func save(_ root: URL, defaults: UserDefaults = .standard) {
        defaults.set(root.standardizedFileURL.path, forKey: key)
    }

    public static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    public static func isDefaultRoot(
        _ root: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> Bool {
        let path = root.standardizedFileURL.path
        if path == AppPaths.defaultRoot(homeDirectory: homeDirectory).standardizedFileURL.path {
            return true
        }
        return AppPaths.legacyDocumentsWorkspaceRoots(homeDirectory: homeDirectory)
            .contains { $0.standardizedFileURL.path == path }
    }
}
