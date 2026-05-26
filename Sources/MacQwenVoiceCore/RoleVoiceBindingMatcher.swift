import Foundation

public enum RoleVoiceBindingMatcher {
    public static func matches(roleName: String, voice: VoiceProfile) -> Bool {
        let roleKey = normalized(roleName)
        guard !roleKey.isEmpty else { return false }
        return candidateKeys(for: voice).contains(roleKey)
    }

    public static func candidateKeys(for voice: VoiceProfile) -> Set<String> {
        var keys: Set<String> = []
        for value in [voice.name, voice.speaker ?? ""] {
            let key = normalized(value)
            if !key.isEmpty {
                keys.insert(key)
            }
            let withoutGeneratedPrefix = normalized(value.replacingOccurrences(of: "角色 · ", with: ""))
            if !withoutGeneratedPrefix.isEmpty {
                keys.insert(withoutGeneratedPrefix)
            }
        }
        return keys
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "：", with: ":")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
    }
}
