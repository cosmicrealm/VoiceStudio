import Foundation

public enum QwenModelDirectoryValidator {
    public static func isReady(atPath path: String) -> Bool {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let url = URL(fileURLWithPath: path)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return false
        }
        guard FileManager.default.fileExists(atPath: url.appendingPathComponent("config.json").path) else {
            return false
        }
        guard let children = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return false
        }
        return children.contains { $0.pathExtension == "safetensors" }
    }
}
