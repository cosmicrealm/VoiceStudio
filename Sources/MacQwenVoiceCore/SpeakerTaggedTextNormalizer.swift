import Foundation

public struct SpeakerTaggedTextLine: Equatable, Sendable {
    public var speaker: String?
    public var spokenText: String
    public var isRoleDefinition: Bool

    public init(speaker: String?, spokenText: String, isRoleDefinition: Bool = false) {
        self.speaker = speaker
        self.spokenText = spokenText
        self.isRoleDefinition = isRoleDefinition
    }
}

public struct SpeakerTaggedScript: Equatable, Sendable {
    public var roleDefinitions: [String: String]
    public var utterances: [SpeakerTaggedTextLine]

    public init(roleDefinitions: [String: String], utterances: [SpeakerTaggedTextLine]) {
        self.roleDefinitions = roleDefinitions
        self.utterances = utterances
    }

    public var hasRoleRouting: Bool {
        !roleDefinitions.isEmpty && utterances.contains { line in
            guard let speaker = line.speaker else { return false }
            return roleDefinitions[speaker] != nil
        }
    }
}

public struct SpeakerTaggedSynthesisSegment: Equatable, Sendable {
    public var index: Int
    public var speaker: String?
    public var text: String
    public var instruction: String?

    public init(index: Int, speaker: String?, text: String, instruction: String?) {
        self.index = index
        self.speaker = speaker
        self.text = text
        self.instruction = instruction
    }
}

public struct SpeakerTaggedRoleReference: Equatable, Sendable {
    public var speaker: String
    public var instruction: String
    public var referenceText: String

    public init(speaker: String, instruction: String, referenceText: String) {
        self.speaker = speaker
        self.instruction = instruction
        self.referenceText = referenceText
    }
}

public enum SpeakerTaggedTextNormalizer {
    public static func lines(from text: String) -> [SpeakerTaggedTextLine] {
        insertMissingLineBreaksAfterRoleDefinitions(in: text.replacingOccurrences(of: "\r\n", with: "\n"))
            .components(separatedBy: "\n")
            .compactMap(line(from:))
    }

    public static func script(from text: String) -> SpeakerTaggedScript {
        let parsedLines = lines(from: text)
        var definitions: [String: String] = [:]
        var utterances: [SpeakerTaggedTextLine] = []
        for line in parsedLines {
            if line.isRoleDefinition, let speaker = line.speaker {
                definitions[speaker] = line.spokenText
            } else {
                utterances.append(line)
            }
        }
        return SpeakerTaggedScript(roleDefinitions: definitions, utterances: utterances)
    }

    public static func script(roleDefinitionsText: String, synthesisText: String) -> SpeakerTaggedScript {
        let definitionScript = script(from: roleDefinitionsText)
        let synthesisScript = script(from: synthesisText)
        var definitions = definitionScript.roleDefinitions
        for (speaker, instruction) in synthesisScript.roleDefinitions where definitions[speaker] == nil {
            definitions[speaker] = instruction
        }
        var utterances = synthesisScript.utterances
        if definitions.count == 1, let singleSpeaker = definitions.keys.first {
            utterances = utterances.map { utterance in
                guard utterance.speaker == nil else { return utterance }
                return SpeakerTaggedTextLine(
                    speaker: singleSpeaker,
                    spokenText: utterance.spokenText,
                    isRoleDefinition: false
                )
            }
        }
        return SpeakerTaggedScript(roleDefinitions: definitions, utterances: utterances)
    }

    public static func synthesisSegments(
        from text: String,
        maxCharacters: Int = 420,
        sentenceLevel: Bool = false
    ) -> [SpeakerTaggedSynthesisSegment] {
        let script = script(from: text)
        let segmenter = TextSegmenter(maxCharacters: maxCharacters)
        var output: [SpeakerTaggedSynthesisSegment] = []
        for utterance in script.utterances {
            let chunks = sentenceLevel
                ? sentenceLevelChunks(from: utterance.spokenText, maxCharacters: maxCharacters)
                : segmenter.segments(from: utterance.spokenText).map(\.text)
            for chunk in chunks {
                let instruction = utterance.speaker.flatMap { script.roleDefinitions[$0] }
                output.append(
                    SpeakerTaggedSynthesisSegment(
                        index: output.count,
                        speaker: utterance.speaker,
                        text: chunk,
                        instruction: instruction
                    )
                )
            }
        }
        return output
    }

    public static func synthesisSegments(
        roleDefinitionsText: String,
        synthesisText: String,
        maxCharacters: Int = 420,
        sentenceLevel: Bool = false
    ) -> [SpeakerTaggedSynthesisSegment] {
        synthesisSegments(
            script: script(roleDefinitionsText: roleDefinitionsText, synthesisText: synthesisText),
            maxCharacters: maxCharacters,
            sentenceLevel: sentenceLevel
        )
    }

    public static func roleControlInstruction(from text: String) -> String {
        lines(from: text)
            .compactMap { line -> String? in
                guard line.isRoleDefinition, let speaker = line.speaker else { return nil }
                return "\"\(speaker)\": \"\(line.spokenText)\""
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func roleRoutedText(from text: String) -> String {
        script(from: text).utterances
            .map { line in
                if let speaker = line.speaker {
                    return roleLabeledText(speaker: speaker, text: line.spokenText)
                }
                return line.spokenText
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func roleNames(from text: String) -> [String] {
        roleNames(script: script(from: text))
    }

    public static func roleNames(roleDefinitionsText: String, synthesisText: String) -> [String] {
        roleNames(script: script(roleDefinitionsText: roleDefinitionsText, synthesisText: synthesisText))
    }

    public static func roleLabeledText(speaker: String, text: String) -> String {
        let speaker = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !speaker.isEmpty, !text.isEmpty else { return text }
        return "\(speaker): \(text)"
    }

    public static func roleReferences(from text: String, maxReferenceCharacters: Int = 180) -> [SpeakerTaggedRoleReference] {
        roleReferences(script: script(from: text), maxReferenceCharacters: maxReferenceCharacters)
    }

    public static func roleReferences(
        roleDefinitionsText: String,
        synthesisText: String,
        maxReferenceCharacters: Int = 180
    ) -> [SpeakerTaggedRoleReference] {
        roleReferences(
            script: script(roleDefinitionsText: roleDefinitionsText, synthesisText: synthesisText),
            maxReferenceCharacters: maxReferenceCharacters
        )
    }

    private static func roleNames(script: SpeakerTaggedScript) -> [String] {
        var seen: Set<String> = []
        var names: [String] = []
        for utterance in script.utterances {
            guard let speaker = utterance.speaker?.trimmingCharacters(in: .whitespacesAndNewlines), !speaker.isEmpty else {
                continue
            }
            if seen.insert(speaker).inserted {
                names.append(speaker)
            }
        }
        return names
    }

    private static func synthesisSegments(
        script: SpeakerTaggedScript,
        maxCharacters: Int,
        sentenceLevel: Bool
    ) -> [SpeakerTaggedSynthesisSegment] {
        let segmenter = TextSegmenter(maxCharacters: maxCharacters)
        var output: [SpeakerTaggedSynthesisSegment] = []
        for utterance in script.utterances {
            let chunks = sentenceLevel
                ? sentenceLevelChunks(from: utterance.spokenText, maxCharacters: maxCharacters)
                : segmenter.segments(from: utterance.spokenText).map(\.text)
            for chunk in chunks {
                let instruction = utterance.speaker.flatMap { script.roleDefinitions[$0] }
                output.append(
                    SpeakerTaggedSynthesisSegment(
                        index: output.count,
                        speaker: utterance.speaker,
                        text: chunk,
                        instruction: instruction
                    )
                )
            }
        }
        return output
    }

    private static func roleReferences(
        script: SpeakerTaggedScript,
        maxReferenceCharacters: Int
    ) -> [SpeakerTaggedRoleReference] {
        guard script.hasRoleRouting else { return [] }
        let segmenter = TextSegmenter(maxCharacters: maxReferenceCharacters)
        var seenSpeakers: Set<String> = []
        var references: [SpeakerTaggedRoleReference] = []
        for utterance in script.utterances {
            guard
                let speaker = utterance.speaker?.trimmingCharacters(in: .whitespacesAndNewlines),
                !speaker.isEmpty,
                !seenSpeakers.contains(speaker),
                let instruction = script.roleDefinitions[speaker]?.trimmingCharacters(in: .whitespacesAndNewlines),
                !instruction.isEmpty
            else {
                continue
            }
            let referenceText = segmenter.segments(from: stableReferenceText(
                speaker: speaker,
                instruction: instruction,
                fallbackText: utterance.spokenText
            )).first?.text
                ?? utterance.spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !referenceText.isEmpty else { continue }
            references.append(
                SpeakerTaggedRoleReference(
                    speaker: speaker,
                    instruction: instruction,
                    referenceText: referenceText
                )
            )
            seenSpeakers.insert(speaker)
        }
        return references
    }

    public static func liveVoiceDesignInstruction(speaker: String, instruction: String) -> String {
        instruction.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func deterministicSeed(speaker: String, instruction: String) -> Int {
        let key = "voice-studio-role-seed-v1|\(speaker.trimmingCharacters(in: .whitespacesAndNewlines))|\(instruction.trimmingCharacters(in: .whitespacesAndNewlines))"
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return Int(hash % 2_000_000_000) + 1
    }

    public static func reusableVoiceDesignInstruction(speaker: String, instruction: String) -> String {
        let speaker = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        let instruction = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        let genderConstraint = voiceGenderConstraint(speaker: speaker, instruction: instruction)
        return """
        请根据以下角色设定创建一个可复用参考音色。只朗读合成文本，不朗读角色名、冒号或任何说明文字。角色名仅用于内部识别：\(speaker)。声音设定：\(instruction)。严格保持设定中的性别、年龄、音高、口音、语速、情绪和声学质感。\(genderConstraint) 这段参考音频后续会作为 Base voice clone 的 ref_audio/ref_text 使用，因此请生成稳定、清晰、可复用的单一角色声线。
        """
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stableReferenceText(speaker: String, instruction: String, fallbackText: String) -> String {
        let profile = "\(speaker) \(instruction)"
        if containsAny(profile, ["旁白", "叙事", "播音", "讲述"]) {
            return "夜色慢慢落下来，窗外的风很轻。我会用平稳清晰的旁白声音，把这段场景完整地读完。"
        }
        switch inferredGender(speaker: speaker, instruction: instruction) {
        case .male:
            return "我先确认一下这件事。虽然有点紧张，但我会放慢呼吸，用清楚稳定的声音把这段话说完。"
        case .female:
            return "请别着急，我会放慢语速，用沉稳清晰的声音，把这一段话完整地说给你听。"
        case .unknown:
            let fallback = fallbackText.trimmingCharacters(in: .whitespacesAndNewlines)
            if fallback.count >= 24, !fallback.contains(":") && !fallback.contains("：") {
                return fallback
            }
            return "夜色慢慢落下来，窗外的风很轻。我用自然、清晰、稳定的声音，把这一段话完整地读完。"
        }
    }

    private enum InferredGender {
        case male
        case female
        case unknown
    }

    private static func inferredGender(speaker: String, instruction: String) -> InferredGender {
        let profile = "\(speaker) \(instruction)"
        let maleHit = containsAny(profile, ["男性", "男声", "男生", "男士", "男人", "少年", "男孩", "大叔", "叔"])
        let femaleHit = containsAny(profile, ["女性", "女声", "女生", "女士", "女人", "少女", "女孩", "御姐", "姐姐", "女播音"])
        if maleHit && !femaleHit { return .male }
        if femaleHit && !maleHit { return .female }
        if maleHit { return .male }
        if femaleHit { return .female }
        return .unknown
    }

    private static func voiceGenderConstraint(speaker: String, instruction: String) -> String {
        switch inferredGender(speaker: speaker, instruction: instruction) {
        case .male:
            return "性别硬约束：必须生成明确男性声线；Male voice only. Do not generate a female voice. 不要生成女性声线或偏女性化的音色。"
        case .female:
            return "性别硬约束：必须生成明确女性声线；Female voice only. Do not generate a male voice. 不要生成男性声线或偏男性化的音色。"
        case .unknown:
            return "如果设定中出现明确性别词，必须严格遵守；不要自行切换到其他性别声线。"
        }
    }

    private static func sentenceLevelChunks(from text: String, maxCharacters: Int) -> [String] {
        let segmenter = TextSegmenter(maxCharacters: maxCharacters)
        var chunks: [String] = []
        var current = ""
        let delimiters: Set<Character> = ["。", "！", "？", "；", ".", "!", "?", ";"]
        for character in text {
            current.append(character)
            if delimiters.contains(character) {
                let sentence = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    chunks.append(contentsOf: segmenter.segments(from: sentence).map(\.text))
                }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            chunks.append(contentsOf: segmenter.segments(from: tail).map(\.text))
        }
        return chunks
    }

    private static func insertMissingLineBreaksAfterRoleDefinitions(in text: String) -> String {
        var output = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            output.append(character)
            let next = text.index(after: index)
            if isQuote(character),
               index != text.startIndex,
               next < text.endIndex,
               rolePrefixStarts(at: next, in: text) {
                let previous = text.index(before: index)
                if text[previous] != "\n",
                   text[previous] != "\r",
                   text[previous] != " ",
                   text[previous] != "\t",
                   text[previous] != ":",
                   text[previous] != "：" {
                    output.append("\n")
                }
            }
            index = next
        }
        return output
    }

    private static func rolePrefixStarts(at index: String.Index, in text: String) -> Bool {
        var cursor = index
        while cursor < text.endIndex, text[cursor] == " " || text[cursor] == "\t" {
            cursor = text.index(after: cursor)
        }
        guard cursor < text.endIndex, text[cursor] != "\n", text[cursor] != "\r" else {
            return false
        }
        var rawLabel = ""
        while cursor < text.endIndex {
            let character = text[cursor]
            if character == ":" || character == "：" {
                let trimmed = rawLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                return isLikelySpeakerLabel(rawLabel: trimmed, normalizedLabel: unquoted(trimmed))
            }
            if character == "\n" || character == "\r" || rawLabel.count > 20 {
                return false
            }
            rawLabel.append(character)
            cursor = text.index(after: cursor)
        }
        return false
    }

    private static func isQuote(_ character: Character) -> Bool {
        character == "\"" || character == "'" || character == "”" || character == "’"
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.localizedCaseInsensitiveContains($0) }
    }

    public static func synthesisText(from text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { rawLine -> String? in
                if rawLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return ""
                }
                guard let line = line(from: String(rawLine)) else { return nil }
                return line.isRoleDefinition ? nil : line.spokenText
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func line(from rawLine: String) -> SpeakerTaggedTextLine? {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let delimiter = firstRoleDelimiter(in: trimmed) else {
            return SpeakerTaggedTextLine(speaker: nil, spokenText: trimmed)
        }

        let rawLabel = String(trimmed[..<delimiter]).trimmingCharacters(in: .whitespacesAndNewlines)
        let restStart = trimmed.index(after: delimiter)
        let rest = String(trimmed[restStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rest.isEmpty else {
            return SpeakerTaggedTextLine(speaker: nil, spokenText: trimmed)
        }
        guard !rest.hasPrefix("//") else {
            return SpeakerTaggedTextLine(speaker: nil, spokenText: trimmed)
        }

        let label = unquoted(rawLabel)
        guard isLikelySpeakerLabel(rawLabel: rawLabel, normalizedLabel: label) else {
            return SpeakerTaggedTextLine(speaker: nil, spokenText: trimmed)
        }

        let definition = isQuoted(rawLabel) && isQuoted(rest)
        return SpeakerTaggedTextLine(
            speaker: label,
            spokenText: definition ? unquoted(rest) : rest,
            isRoleDefinition: definition
        )
    }

    private static func firstRoleDelimiter(in line: String) -> String.Index? {
        line.firstIndex { $0 == ":" || $0 == "：" }
    }

    private static func isLikelySpeakerLabel(rawLabel: String, normalizedLabel: String) -> Bool {
        guard !normalizedLabel.isEmpty, normalizedLabel.count <= 20 else { return false }
        guard rawLabel.rangeOfCharacter(from: CharacterSet(charactersIn: "/\\{}[]()=+-")) == nil else { return false }
        guard rawLabel.rangeOfCharacter(from: .decimalDigits) == nil else { return false }
        if rawLabel.rangeOfCharacter(from: .whitespacesAndNewlines) != nil, !isQuoted(rawLabel) {
            return false
        }
        return true
    }

    private static func isQuoted(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, let last = trimmed.last, trimmed.count >= 2 else {
            return false
        }
        return (first == "\"" && last == "\"")
            || (first == "'" && last == "'")
            || (first == "“" && last == "”")
            || (first == "‘" && last == "’")
    }

    private static func unquoted(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isQuoted(trimmed) else { return trimmed }
        return String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
