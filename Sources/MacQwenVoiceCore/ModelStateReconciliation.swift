import Foundation

public enum ModelStateReconciliation {
    public static func shouldPersistRuntimeReadyPath(
        current: ModelState?,
        stored: ModelState?,
        runtimePath: String
    ) -> Bool {
        guard let savedPath = nonEmptyPath(current?.localPath) ?? nonEmptyPath(stored?.localPath) else {
            return true
        }
        return normalizedPath(savedPath) == normalizedPath(runtimePath)
    }

    private static func nonEmptyPath(_ path: String?) -> String? {
        guard let path else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}
