import Foundation

public struct CloneReferenceTranscriptExampleGroup: Equatable, Sendable {
    public let language: String
    public let examples: [String]

    public init(language: String, examples: [String]) {
        self.language = language
        self.examples = examples
    }
}

public enum VoiceStudioDefaults {
    public static let appDisplayName = "Voice Studio"
    public static let defaultProjectTitle = "新旁白项目"
    public static let defaultBuiltinControlInstruction = "阳光温暖，声音自然洪亮，吐字清晰，语速适中，表达亲切有感染力。"
    public static let defaultVoiceDesignControlInstruction = defaultBuiltinControlInstruction
    public static let cloneReferenceTranscript = "夜色慢慢落下来，窗外的风很轻，我用平稳而清晰的声音读完这一段话。"
    public static let cloneReferenceTranscriptExamples: [CloneReferenceTranscriptExampleGroup] = [
        .init(
            language: "中文",
            examples: [
                cloneReferenceTranscript,
                "今天的空气很安静，像是把所有匆忙都轻轻放慢了一点。",
                "我想把这句话说得温柔一些，也说得清楚一些，让你能听见每一个停顿。",
                "远处的灯一点点亮起来，城市的声音也慢慢变得柔和。",
                "如果你正在听这段声音，希望它听起来真实、自然，也带着一点温暖。",
                "我们先慢慢开始，不急着抵达，只把眼前这一句话认真说完。"
            ]
        ),
        .init(
            language: "English",
            examples: [
                "The evening is getting quiet, and I am reading this sentence in a calm and natural voice.",
                "I want this voice to sound clear, warm, and easy to listen to.",
                "Let us take a slow breath and say this line with a gentle, steady rhythm.",
                "The room is peaceful tonight, and every word should feel simple and close.",
                "I am speaking naturally, with a little warmth and enough space between the words.",
                "This is a short reference recording, made to keep the voice clear and consistent."
            ]
        )
    ]

    public static var allCloneReferenceTranscriptExamples: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for example in cloneReferenceTranscriptExamples.flatMap(\.examples) {
            let trimmed = example.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            result.append(trimmed)
        }
        return result
    }
}
