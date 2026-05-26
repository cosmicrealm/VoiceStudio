import Foundation

public struct VoiceToolsAudioMergePlan: Equatable, Sendable {
    public var paths: [String]
    public var outputName: String

    public init(paths: [String], outputName: String) {
        self.paths = paths
        self.outputName = outputName
    }
}

public enum VoiceToolsAudioMergePlanner {
    private static let supportedAudioExtensions: Set<String> = [
        "webm", "wav", "mp3", "m4a", "aac", "flac", "ogg", "opus", "aiff", "aif", "caf"
    ]

    public static func plan(paths: [String], outputName: String) -> VoiceToolsAudioMergePlan? {
        let trimmedPaths = paths.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard trimmedPaths.count > 1, trimmedPaths.allSatisfy({ isSupportedAudioPath($0) }) else {
            return nil
        }
        let trimmedOutputName = outputName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOutputName.isEmpty else { return nil }
        let normalizedOutputName = trimmedOutputName.lowercased().hasSuffix(".webm")
            ? trimmedOutputName
            : "\(trimmedOutputName).webm"
        return VoiceToolsAudioMergePlan(paths: trimmedPaths, outputName: normalizedOutputName)
    }

    public static func isSupportedAudioPath(_ path: String) -> Bool {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let ext = URL(fileURLWithPath: trimmed).pathExtension.lowercased()
        return supportedAudioExtensions.contains(ext)
    }
}
