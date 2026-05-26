import Foundation

public enum BuiltinVoiceDisplayName {
    private static let namesBySpeaker: [String: String] = [
        "Serena": "苏瑶 Serena",
        "Uncle_Fu": "福伯 Uncle Fu",
        "Uncle Fu": "福伯 Uncle Fu",
        "Vivian": "十三 Vivian",
        "Aiden": "艾登 Aiden",
        "Ryan": "甜茶 Ryan",
        "Ono_Anna": "小野杏 Ono Anna",
        "Ono Anna": "小野杏 Ono Anna",
        "Sohee": "素熙 Sohee",
        "Dylan": "晓东 Dylan",
        "Eric": "程川 Eric"
    ]

    private static let nativeLanguageBySpeaker: [String: String] = [
        "Vivian": "中文",
        "Serena": "中文",
        "Uncle_Fu": "中文",
        "Uncle Fu": "中文",
        "Dylan": "北京话",
        "Eric": "四川话",
        "Ryan": "英文",
        "Aiden": "英文",
        "Ono_Anna": "日语",
        "Ono Anna": "日语",
        "Sohee": "韩语"
    ]

    private static let defaultLanguageChoiceBySpeaker: [String: ScriptStudioLanguageChoice] = [
        "Vivian": .chinese,
        "Serena": .chinese,
        "Uncle_Fu": .chinese,
        "Uncle Fu": .chinese,
        "Dylan": .beijingDialect,
        "Eric": .sichuanDialect,
        "Ryan": .english,
        "Aiden": .english,
        "Ono_Anna": .japanese,
        "Ono Anna": .japanese,
        "Sohee": .korean
    ]

    public static func displayName(for voice: VoiceProfile) -> String {
        if containsCJK(voice.name) {
            return voice.name
        }
        if let speaker = voice.speaker, let mapped = namesBySpeaker[speaker] {
            return mapped
        }
        if let mapped = namesBySpeaker[voice.name] {
            return mapped
        }
        return voice.name
    }

    public static func displayNameWithNativeLanguage(for voice: VoiceProfile) -> String {
        "\(displayName(for: voice)) · \(nativeLanguageLabel(for: voice))"
    }

    public static func nativeLanguageLabel(for voice: VoiceProfile) -> String {
        if let speaker = voice.speaker, let mapped = nativeLanguageBySpeaker[speaker] {
            return mapped
        }
        if let mapped = nativeLanguageBySpeaker[voice.name] {
            return mapped
        }
        return localizedLanguageLabel(voice.language)
    }

    public static func defaultLanguageChoice(for voice: VoiceProfile) -> ScriptStudioLanguageChoice {
        if let speaker = voice.speaker, let mapped = defaultLanguageChoiceBySpeaker[speaker] {
            return mapped
        }
        if let mapped = defaultLanguageChoiceBySpeaker[voice.name] {
            return mapped
        }
        switch voice.language.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "chinese", "zh", "zh_cn", "zh-cn", "中文", "普通话":
            return .chinese
        case "beijing_dialect", "beijing dialect", "北京话":
            return .beijingDialect
        case "sichuan_dialect", "sichuan dialect", "四川话":
            return .sichuanDialect
        case "english", "en", "英语", "英文":
            return .english
        case "japanese", "ja", "日语", "日本語":
            return .japanese
        case "korean", "ko", "韩语", "한국어":
            return .korean
        case "russian", "ru", "俄语":
            return .russian
        default:
            return .automatic
        }
    }

    public static func chineseName(for voice: VoiceProfile) -> String? {
        let displayName = displayName(for: voice)
        guard let firstToken = displayName.split(separator: " ").first else {
            return nil
        }
        let value = String(firstToken)
        return containsCJK(value) ? value : nil
    }

    private static func localizedLanguageLabel(_ value: String) -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "chinese":
            return "中文"
        case "beijing_dialect", "beijing dialect":
            return "北京话"
        case "sichuan_dialect", "sichuan dialect":
            return "四川话"
        case "english", "英语", "英文":
            return "英文"
        case "japanese", "日语", "日本語":
            return "日语"
        case "korean", "韩语", "한국어":
            return "韩语"
        case "german":
            return "德语"
        case "french":
            return "法语"
        case "russian":
            return "俄语"
        case "portuguese":
            return "葡萄牙语"
        case "spanish":
            return "西班牙语"
        case "italian":
            return "意大利语"
        default:
            return value.isEmpty ? "未知语种" : value
        }
    }

    private static func containsCJK(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }
}

public enum ChineseOrdinalFormatter {
    public static func item(_ value: Int) -> String {
        "第\(number(value))个"
    }

    public static func page(_ value: Int) -> String {
        "第\(number(value))页"
    }

    public static func number(_ value: Int) -> String {
        guard value > 0 else { return "\(value)" }
        if value <= 99 {
            return twoDigitNumber(value)
        }
        return "\(value)"
    }

    private static func twoDigitNumber(_ value: Int) -> String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        if value < 10 {
            return digits[value]
        }
        let tens = value / 10
        let ones = value % 10
        if tens == 1 {
            return ones == 0 ? "十" : "十\(digits[ones])"
        }
        return ones == 0 ? "\(digits[tens])十" : "\(digits[tens])十\(digits[ones])"
    }
}
