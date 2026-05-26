import Foundation

public struct HuggingFaceDownloadPlan: Equatable, Sendable {
    public static let officialEndpoint = ""
    public static let mirrorEndpoint = "https://hf-mirror.com"

    public var repository: String
    public var localPath: String
    public var endpoint: String

    public init(repository: String, localPath: String, endpoint: String = "") {
        self.repository = repository
        self.localPath = localPath
        self.endpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var normalizedEndpoint: String? {
        endpoint.isEmpty ? nil : endpoint
    }

    public var displayName: String {
        normalizedEndpoint ?? "Hugging Face 官方源"
    }

    public var shellCommand: String {
        let base = "hf \(downloadArguments.map(Self.shellQuote).joined(separator: " "))"
        guard let normalizedEndpoint else { return base }
        return "HF_ENDPOINT=\"\(normalizedEndpoint)\" \(base)"
    }

    public var processEnvironment: [String: String] {
        guard let normalizedEndpoint else { return [:] }
        return ["HF_ENDPOINT": normalizedEndpoint]
    }

    public var downloadArguments: [String] {
        ["download", repository, "--local-dir", localPath]
    }

    public var dryRunArguments: [String] {
        downloadArguments + ["--dry-run", "--format", "json"]
    }

    public func fallbackToOfficial() -> HuggingFaceDownloadPlan {
        HuggingFaceDownloadPlan(repository: repository, localPath: localPath, endpoint: Self.officialEndpoint)
    }

    private static func shellQuote(_ value: String) -> String {
        if value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
           !value.contains("\""),
           !value.hasPrefix("/") {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}

public enum HuggingFaceEndpointPreference {
    public static let key = "MacQwenVoice.huggingFaceEndpoint"

    public static func load(
        defaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String {
        if let stored = defaults.object(forKey: key) as? String {
            return stored
        }
        return environment["HF_ENDPOINT"] ?? HuggingFaceDownloadPlan.mirrorEndpoint
    }

    public static func save(_ endpoint: String, defaults: UserDefaults = .standard) {
        defaults.set(endpoint.trimmingCharacters(in: .whitespacesAndNewlines), forKey: key)
    }
}
