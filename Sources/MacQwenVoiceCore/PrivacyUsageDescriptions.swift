import Foundation

public enum PrivacyUsageDescriptions {
    public enum Capability: Sendable {
        case microphone
        case speechRecognition
    }

    public static let microphoneKey = "NSMicrophoneUsageDescription"
    public static let speechRecognitionKey = "NSSpeechRecognitionUsageDescription"

    public static func missingKeys(
        for capabilities: [Capability],
        in infoDictionary: [String: Any]?
    ) -> [String] {
        let dictionary = infoDictionary ?? [:]
        return capabilities.compactMap { capability in
            let key = plistKey(for: capability)
            return hasNonEmptyString(for: key, in: dictionary) ? nil : key
        }
    }

    public static func plistKey(for capability: Capability) -> String {
        switch capability {
        case .microphone:
            return microphoneKey
        case .speechRecognition:
            return speechRecognitionKey
        }
    }

    private static func hasNonEmptyString(for key: String, in dictionary: [String: Any]) -> Bool {
        guard let value = dictionary[key] as? String else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
