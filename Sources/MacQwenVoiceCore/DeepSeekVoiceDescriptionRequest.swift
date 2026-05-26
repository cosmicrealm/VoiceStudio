import Foundation

public struct DeepSeekVoiceDescriptionRequest: Equatable, Sendable {
    public static let savedKeyPlaceholder = "********"

    public let description: String
    public let language: String
    public let purpose: String
    public let controlType: String
    public let synthesisText: String
    public let currentInstruction: String

    public init(
        description: String,
        language: String,
        purpose: String,
        controlType: String = "VoiceDesign 角色音色卡",
        synthesisText: String = "",
        currentInstruction: String = ""
    ) {
        self.description = description
        self.language = language
        self.purpose = purpose
        self.controlType = controlType
        self.synthesisText = synthesisText
        self.currentInstruction = currentInstruction
    }

    public static func resolvedAPIKey(apiKey: String?, environment: [String: String] = ProcessInfo.processInfo.environment) -> String? {
        let explicit = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !explicit.isEmpty {
            return explicit
        }
        let fromEnvironment = environment["DEEPSEEK_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fromEnvironment.isEmpty ? nil : fromEnvironment
    }

    public static func isConfigured(apiKey: String?, environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        resolvedAPIKey(apiKey: apiKey, environment: environment) != nil
    }

    public static func isSavedKeyPlaceholder(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines) == savedKeyPlaceholder
    }

    public var requestBody: [String: Any] {
        [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a Qwen3-TTS prompt agent for VoiceDesign and CustomVoice instruction control. Your job is to enrich the user's original instruction, not replace it. You must preserve every original constraint, must not delete any user-provided constraint, and must only add concrete controllable detail around official-style control types: acoustic attributes, age/identity, emotion and acting, gradient control, persona/background, human-likeness, language/dialect, and multi-role timbre reuse. Never imitate a specific real person's identity or voice. Return strict JSON only.
                    """
                ],
                [
                    "role": "user",
                    "content": """
                    Target language: \(language)
                    Usage: \(purpose)
                    Control type: \(controlType)
                    Raw user description: \(description)
                    Current compiled instruction: \(currentInstruction)
                    Synthesis text for preview: \(synthesisText)

                    Return a JSON object with exactly these keys:
                    - role_name
                    - model_route
                    - voice_identity
                    - acoustic_features
                    - prosody
                    - emotion_and_acting
                    - dynamic_curve
                    - scene_context
                    - language_accent
                    - negative_constraints
                    - enriched_instruction
                    - compiled_instruction
                    - preserved_constraints
                    - coverage_warnings
                    - preview_text

                    Preservation rules:
                    - enriched_instruction and compiled_instruction must preserve every original constraint from Raw user description and Current compiled instruction.
                    - They must not delete, weaken, contradict, summarize away, or silently omit original constraints.
                    - If a constraint is ambiguous or unsafe, keep the safe part and explain the issue in coverage_warnings.

                    The enriched_instruction must be directly usable as Qwen3-TTS VoiceDesign or CustomVoice instruct/prompt text. Prefer concrete controllable attributes over vague labels such as "natural narration".
                    """
                ]
            ],
            "temperature": 0.7
        ]
    }
}

public enum DeepSeekVoiceDescriptionResponse {
    public static func preferredInstruction(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        if let json = jsonObjectString(from: trimmed),
           let data = json.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let instruction = (object["enriched_instruction"] as? String) ?? (object["compiled_instruction"] as? String) {
            let cleaned = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                return cleaned
            }
        }
        return trimmed
    }

    private static func jsonObjectString(from content: String) -> String? {
        if content.hasPrefix("{"), content.hasSuffix("}") {
            return content
        }
        guard
            let start = content.firstIndex(of: "{"),
            let end = content.lastIndex(of: "}")
        else {
            return nil
        }
        return String(content[start...end])
    }
}
