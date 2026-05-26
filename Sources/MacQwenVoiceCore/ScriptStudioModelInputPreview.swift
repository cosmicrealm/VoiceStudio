import Foundation

public enum ScriptStudioDetectedLanguage: String, Codable, Equatable, Sendable {
    case chinese = "Chinese"
    case english = "English"
    case japanese = "Japanese"
    case korean = "Korean"
    case russian = "Russian"
    case mixed = "Mixed"
    case unknown = "Unknown"

    public var displayTitle: String {
        switch self {
        case .chinese: "中文"
        case .english: "英文"
        case .japanese: "日语"
        case .korean: "韩语"
        case .russian: "俄语"
        case .mixed: "混合"
        case .unknown: "未知"
        }
    }
}

public enum ScriptStudioLanguageDetector {
    public static func detect(_ text: String) -> ScriptStudioDetectedLanguage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .unknown }

        var hasHan = false
        var hasLatin = false
        var hasJapaneseKana = false
        var hasHangul = false
        var hasCyrillic = false

        for scalar in trimmed.unicodeScalars {
            switch scalar.value {
            case 0x0041...0x005A, 0x0061...0x007A:
                hasLatin = true
            case 0x3040...0x30FF:
                hasJapaneseKana = true
            case 0xAC00...0xD7AF, 0x1100...0x11FF, 0x3130...0x318F:
                hasHangul = true
            case 0x0400...0x04FF:
                hasCyrillic = true
            case 0x4E00...0x9FFF:
                hasHan = true
            default:
                continue
            }
        }

        var languages: Set<ScriptStudioDetectedLanguage> = []
        if hasJapaneseKana {
            languages.insert(.japanese)
        } else if hasHan {
            languages.insert(.chinese)
        }
        if hasHangul {
            languages.insert(.korean)
        }
        if hasCyrillic {
            languages.insert(.russian)
        }
        if hasLatin {
            languages.insert(.english)
        }

        if languages.count > 1 {
            return .mixed
        }
        return languages.first ?? .unknown
    }
}

public enum ScriptStudioLanguageOption: String, Codable, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case automatic
    case chinese
    case beijingDialect
    case sichuanDialect
    case english
    case japanese
    case korean
    case german
    case french
    case russian
    case portuguese
    case spanish
    case italian

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .automatic: "自动"
        case .chinese: "中文"
        case .beijingDialect: "北京话"
        case .sichuanDialect: "四川话"
        case .english: "英文"
        case .japanese: "日语"
        case .korean: "韩语"
        case .german: "德语"
        case .french: "法语"
        case .russian: "俄语"
        case .portuguese: "葡萄牙语"
        case .spanish: "西班牙语"
        case .italian: "意大利语"
        }
    }

    public var requestValue: String {
        switch self {
        case .automatic: "Auto"
        case .chinese: "Chinese"
        case .beijingDialect: "beijing_dialect"
        case .sichuanDialect: "sichuan_dialect"
        case .english: "English"
        case .japanese: "Japanese"
        case .korean: "Korean"
        case .german: "German"
        case .french: "French"
        case .russian: "Russian"
        case .portuguese: "Portuguese"
        case .spanish: "Spanish"
        case .italian: "Italian"
        }
    }

    public var requiresCustomVoiceModel: Bool {
        switch self {
        case .beijingDialect, .sichuanDialect:
            return true
        case .automatic, .chinese, .english, .japanese, .korean, .german, .french, .russian, .portuguese, .spanish, .italian:
            return false
        }
    }
}

public struct ScriptStudioLanguageChoice: Codable, Equatable, Sendable {
    public var selectedOptions: [ScriptStudioLanguageOption]

    public init(selectedOptions: [ScriptStudioLanguageOption] = [.automatic]) {
        self.selectedOptions = Self.normalized(selectedOptions)
    }

    public static let automatic = ScriptStudioLanguageChoice(selectedOptions: [.automatic])
    public static let chinese = ScriptStudioLanguageChoice(selectedOptions: [.chinese])
    public static let beijingDialect = ScriptStudioLanguageChoice(selectedOptions: [.beijingDialect])
    public static let sichuanDialect = ScriptStudioLanguageChoice(selectedOptions: [.sichuanDialect])
    public static let english = ScriptStudioLanguageChoice(selectedOptions: [.english])
    public static let japanese = ScriptStudioLanguageChoice(selectedOptions: [.japanese])
    public static let korean = ScriptStudioLanguageChoice(selectedOptions: [.korean])
    public static let russian = ScriptStudioLanguageChoice(selectedOptions: [.russian])

    public static func manual(_ options: Set<ScriptStudioLanguageOption>) -> ScriptStudioLanguageChoice {
        ScriptStudioLanguageChoice(selectedOptions: Array(options))
    }

    public func contains(_ option: ScriptStudioLanguageOption) -> Bool {
        selectedOptions.contains(option)
    }

    public func toggled(_ option: ScriptStudioLanguageOption) -> ScriptStudioLanguageChoice {
        if option == .automatic {
            return .automatic
        }

        var next = Set(selectedOptions.filter { $0 != .automatic })
        if next.contains(option) {
            next.remove(option)
        } else {
            next.insert(option)
        }
        return ScriptStudioLanguageChoice(selectedOptions: Array(next))
    }

    public var isAutomatic: Bool {
        selectedOptions == [.automatic]
    }

    public var title: String {
        if isAutomatic {
            return ScriptStudioLanguageOption.automatic.displayTitle
        }
        return selectedOptions.map(\.displayTitle).joined(separator: " + ")
    }

    public func requestLanguage(for text: String) -> String {
        if isAutomatic {
            switch ScriptStudioLanguageDetector.detect(text) {
            case .chinese:
                return "Chinese"
            case .english:
                return "English"
            case .japanese:
                return "Japanese"
            case .korean:
                return "Korean"
            case .russian:
                return "Russian"
            case .mixed, .unknown:
                return "Auto"
            }
        }

        guard selectedOptions.count == 1, let option = selectedOptions.first else {
            return "Auto"
        }
        return option.requestValue
    }

    public func displayLabel(for text: String) -> String {
        if isAutomatic {
            return ScriptStudioLanguageDetector.detect(text).displayTitle
        }
        return title
    }

    private static func normalized(_ options: [ScriptStudioLanguageOption]) -> [ScriptStudioLanguageOption] {
        let manualOptions = Set(options.filter { $0 != .automatic })
        guard !manualOptions.isEmpty else {
            return [.automatic]
        }
        return ScriptStudioLanguageOption.allCases.filter { manualOptions.contains($0) }
    }
}

extension ScriptStudioLanguageChoice: Identifiable {
    public var id: String {
        selectedOptions.map(\.rawValue).joined(separator: "+")
    }
}

extension ScriptStudioLanguageChoice {
    public static var manualOptions: [ScriptStudioLanguageOption] {
        ScriptStudioLanguageOption.allCases.filter { $0 != .automatic }
    }

    public static var toggleOptions: [ScriptStudioLanguageOption] {
        ScriptStudioLanguageOption.allCases
    }

    public static func toggleOptions(for workflow: ScriptStudioWorkflow) -> [ScriptStudioLanguageOption] {
        switch workflow {
        case .builtin:
            return toggleOptions
        case .custom, .voiceDesign, .multiRole:
            return toggleOptions.filter { !$0.requiresCustomVoiceModel }
        }
    }

    public func constrained(to workflow: ScriptStudioWorkflow) -> ScriptStudioLanguageChoice {
        let allowedOptions = Set(Self.toggleOptions(for: workflow))
        return ScriptStudioLanguageChoice(selectedOptions: selectedOptions.filter { allowedOptions.contains($0) })
    }

    public var requestUsesAutoForManualCombination: Bool {
        !isAutomatic && selectedOptions.count > 1
    }

    public func requestHint(for text: String) -> String {
        let detected = ScriptStudioLanguageDetector.detect(text).displayTitle
        if requestUsesAutoForManualCombination {
            return "检测：\(detected) · \(title) 按 Auto 送入后端"
        }
        return "检测：\(detected) · 发送：\(requestLanguage(for: text))"
    }
}

public enum ScriptStudioModelInputField: String, Codable, Equatable, Sendable {
    case text
    case language
    case speaker
    case instruct
    case refAudio
    case refText
}

public struct ScriptStudioModelInputPreview: Equatable, Sendable {
    public var workflow: ScriptStudioWorkflow
    public var visibleFields: [ScriptStudioModelInputField]
    public var text: String
    public var detectedLanguage: ScriptStudioDetectedLanguage
    public var displayLanguage: String
    public var requestLanguage: String
    public var languageChoice: ScriptStudioLanguageChoice
    public var speaker: String?
    public var instruct: String
    public var isInstructEditable: Bool
    public var disabledInstructReason: String?
    public var refAudioPath: String?
    public var refText: String?
    public var missingRequirements: [String]

    public var showsInstructionEditor: Bool {
        visibleFields.contains(.instruct) && isInstructEditable
    }

    public static func make(
        workflow: ScriptStudioWorkflow,
        text: String,
        languageChoice: ScriptStudioLanguageChoice,
        speaker: String,
        instruct: String,
        refAudioPath: String,
        refText: String,
        preserveRoleLabels: Bool = false
    ) -> ScriptStudioModelInputPreview {
        let synthesisText = preserveRoleLabels
            ? text.trimmingCharacters(in: .whitespacesAndNewlines)
            : SpeakerTaggedTextNormalizer.synthesisText(from: text)
        let detectedLanguage = ScriptStudioLanguageDetector.detect(synthesisText)
        let resolvedLanguageChoice = languageChoice.constrained(to: workflow)
        let displayLanguage = resolvedLanguageChoice.displayLabel(for: synthesisText)
        let requestLanguage = resolvedLanguageChoice.requestLanguage(for: synthesisText)
        let speaker = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        let instruct = instruct.trimmingCharacters(in: .whitespacesAndNewlines)
        let refAudioPath = refAudioPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let refText = refText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch workflow {
        case .builtin:
            var missing: [String] = []
            if synthesisText.isEmpty { missing.append("text") }
            if requestLanguage.isEmpty { missing.append("language") }
            if speaker.isEmpty { missing.append("speaker") }
            return ScriptStudioModelInputPreview(
                workflow: workflow,
                visibleFields: [.language, .instruct],
                text: synthesisText,
                detectedLanguage: detectedLanguage,
                displayLanguage: displayLanguage,
                requestLanguage: requestLanguage,
                languageChoice: resolvedLanguageChoice,
                speaker: speaker.isEmpty ? nil : speaker,
                instruct: instruct,
                isInstructEditable: true,
                disabledInstructReason: nil,
                refAudioPath: nil,
                refText: nil,
                missingRequirements: missing
            )
        case .custom:
            var missing: [String] = []
            if synthesisText.isEmpty { missing.append("text") }
            if requestLanguage.isEmpty { missing.append("language") }
            if refAudioPath.isEmpty { missing.append("ref_audio") }
            if refText.isEmpty { missing.append("ref_text") }
            return ScriptStudioModelInputPreview(
                workflow: workflow,
                visibleFields: [.language, .refAudio, .refText],
                text: synthesisText,
                detectedLanguage: detectedLanguage,
                displayLanguage: displayLanguage,
                requestLanguage: requestLanguage,
                languageChoice: resolvedLanguageChoice,
                speaker: nil,
                instruct: "",
                isInstructEditable: false,
                disabledInstructReason: "Base Clone 不使用指令控制；音色来自 ref_audio + ref_text。",
                refAudioPath: refAudioPath.isEmpty ? nil : refAudioPath,
                refText: refText.isEmpty ? nil : refText,
                missingRequirements: missing
            )
        case .multiRole:
            var missing: [String] = []
            if synthesisText.isEmpty { missing.append("text") }
            if requestLanguage.isEmpty { missing.append("language") }
            return ScriptStudioModelInputPreview(
                workflow: workflow,
                visibleFields: [.language],
                text: synthesisText,
                detectedLanguage: detectedLanguage,
                displayLanguage: displayLanguage,
                requestLanguage: requestLanguage,
                languageChoice: resolvedLanguageChoice,
                speaker: nil,
                instruct: "",
                isInstructEditable: false,
                disabledInstructReason: "对话生成不使用角色控制指令；角色声线来自已绑定音色的 ref_audio/ref_text。",
                refAudioPath: nil,
                refText: nil,
                missingRequirements: missing
            )
        case .voiceDesign:
            var missing: [String] = []
            if synthesisText.isEmpty { missing.append("text") }
            if requestLanguage.isEmpty { missing.append("language") }
            if instruct.isEmpty { missing.append("instruct") }
            return ScriptStudioModelInputPreview(
                workflow: workflow,
                visibleFields: [.language, .instruct],
                text: synthesisText,
                detectedLanguage: detectedLanguage,
                displayLanguage: displayLanguage,
                requestLanguage: requestLanguage,
                languageChoice: resolvedLanguageChoice,
                speaker: nil,
                instruct: instruct,
                isInstructEditable: true,
                disabledInstructReason: nil,
                refAudioPath: nil,
                refText: nil,
                missingRequirements: missing
            )
        }
    }
}
