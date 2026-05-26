import Foundation

public enum VoiceControlCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case general
    case acousticAttributes
    case ageIdentity
    case emotionActing
    case gradientControl
    case personaBackground
    case humanLikeness
    case multilingualDialect
    case timbreReuse

    public var title: String {
        switch self {
        case .general: "通用"
        case .acousticAttributes: "声学属性"
        case .ageIdentity: "年龄/身份"
        case .emotionActing: "情绪表演"
        case .gradientControl: "渐变控制"
        case .personaBackground: "角色背景"
        case .humanLikeness: "拟人感"
        case .multilingualDialect: "语言/方言"
        case .timbreReuse: "音色复用"
        }
    }
}

public struct VoiceControlProfile: Codable, Equatable, Sendable {
    public var roleName: String
    public var language: String
    public var dialect: String
    public var age: String
    public var genderPresentation: String
    public var pitch: String
    public var speed: String
    public var volume: String
    public var clarity: String
    public var fluency: String
    public var accent: String
    public var emotion: String
    public var tone: String
    public var persona: String
    public var acousticTexture: String
    public var humanLikeness: String
    public var background: String
    public var gradient: String
    public var negativePrompt: String
    public var customPrompt: String

    public init(
        roleName: String = "",
        language: String = "",
        dialect: String = "",
        age: String = "",
        genderPresentation: String = "",
        pitch: String = "",
        speed: String = "",
        volume: String = "",
        clarity: String = "",
        fluency: String = "",
        accent: String = "",
        emotion: String = "",
        tone: String = "",
        persona: String = "",
        acousticTexture: String = "",
        humanLikeness: String = "",
        background: String = "",
        gradient: String = "",
        negativePrompt: String = "",
        customPrompt: String = ""
    ) {
        self.roleName = roleName
        self.language = language
        self.dialect = dialect
        self.age = age
        self.genderPresentation = genderPresentation
        self.pitch = pitch
        self.speed = speed
        self.volume = volume
        self.clarity = clarity
        self.fluency = fluency
        self.accent = accent
        self.emotion = emotion
        self.tone = tone
        self.persona = persona
        self.acousticTexture = acousticTexture
        self.humanLikeness = humanLikeness
        self.background = background
        self.gradient = gradient
        self.negativePrompt = negativePrompt
        self.customPrompt = customPrompt
    }

    public static let defaultNarration = VoiceControlProfile(
        roleName: "旁白",
        language: "中文",
        dialect: "普通话",
        speed: "语速自然",
        volume: "音量中等",
        clarity: "吐字清楚",
        fluency: "停顿自然，表达连贯",
        emotion: "温柔、清晰、自然",
        acousticTexture: "温暖、稳定、适合旁白"
    )

    public var trimmed: VoiceControlProfile {
        VoiceControlProfile(
            roleName: roleName.trimmed,
            language: language.trimmed,
            dialect: dialect.trimmed,
            age: age.trimmed,
            genderPresentation: genderPresentation.trimmed,
            pitch: pitch.trimmed,
            speed: speed.trimmed,
            volume: volume.trimmed,
            clarity: clarity.trimmed,
            fluency: fluency.trimmed,
            accent: accent.trimmed,
            emotion: emotion.trimmed,
            tone: tone.trimmed,
            persona: persona.trimmed,
            acousticTexture: acousticTexture.trimmed,
            humanLikeness: humanLikeness.trimmed,
            background: background.trimmed,
            gradient: gradient.trimmed,
            negativePrompt: negativePrompt.trimmed,
            customPrompt: customPrompt.trimmed
        )
    }

    public var isEmpty: Bool {
        let profile = trimmed
        return [
            profile.roleName,
            profile.language,
            profile.dialect,
            profile.age,
            profile.genderPresentation,
            profile.pitch,
            profile.speed,
            profile.volume,
            profile.clarity,
            profile.fluency,
            profile.accent,
            profile.emotion,
            profile.tone,
            profile.persona,
            profile.acousticTexture,
            profile.humanLikeness,
            profile.background,
            profile.gradient,
            profile.negativePrompt,
            profile.customPrompt
        ].allSatisfy { $0.isEmpty }
    }
}

public enum VoiceControlPromptCompiler {
    public static func compile(profile: VoiceControlProfile, workflow: ScriptStudioWorkflow) -> String {
        let profile = profile.trimmed
        guard !profile.isEmpty else { return "" }
        switch workflow {
        case .builtin:
            return compileCustomVoiceInstruction(profile)
        case .custom, .multiRole:
            return compileBaseCloneInstruction(profile)
        case .voiceDesign:
            return compileVoiceDesignRoleCard(profile)
        }
    }

    private static func compileVoiceDesignRoleCard(_ profile: VoiceControlProfile) -> String {
        var lines: [String] = []
        appendLine("角色姓名", values: [profile.roleName], to: &lines)
        appendLine("语言与口音", pairs: [
            ("语言", profile.language),
            ("口音", profile.accent)
        ], to: &lines)
        appendLine("声音身份", values: [
            profile.age,
            profile.genderPresentation,
            profile.persona
        ], to: &lines)
        appendLine("声学属性", pairs: [
            ("性别/声线", profile.genderPresentation),
            ("音高", profile.pitch),
            ("语速", profile.speed),
            ("音量", profile.volume),
            ("清晰度", profile.clarity),
            ("流畅度", profile.fluency),
            ("音色质感", profile.acousticTexture)
        ], to: &lines)
        appendLine("情绪与表演", pairs: [
            ("情绪", profile.emotion),
            ("语调", profile.tone),
            ("拟人感", profile.humanLikeness)
        ], to: &lines)
        appendLine("背景信息", values: [profile.background], to: &lines)
        appendLine("动态变化", values: [profile.gradient], to: &lines)
        appendLine("约束", values: [profile.negativePrompt], to: &lines)
        appendLine("补充指令", values: [profile.customPrompt], to: &lines)
        return lines.joined(separator: "\n")
    }

    private static func compileCustomVoiceInstruction(_ profile: VoiceControlProfile) -> String {
        var lines: [String] = []
        appendLine("语言与口音", pairs: [
            ("语言", profile.language),
            ("方言", profile.dialect),
            ("口音", profile.accent)
        ], to: &lines)
        appendLine("声学属性", pairs: [
            ("音高", profile.pitch),
            ("语速", profile.speed),
            ("音量", profile.volume),
            ("清晰度", profile.clarity),
            ("流畅度", profile.fluency),
            ("音色质感", profile.acousticTexture)
        ], to: &lines)
        appendLine("演绎风格", pairs: [
            ("情绪", profile.emotion),
            ("语调", profile.tone),
            ("拟人感", profile.humanLikeness),
            ("场景", profile.background)
        ], to: &lines)
        appendLine("动态变化", values: [profile.gradient], to: &lines)
        appendLine("补充指令", values: [profile.customPrompt], to: &lines)
        return lines.joined(separator: "\n")
    }

    private static func compileBaseCloneInstruction(_ profile: VoiceControlProfile) -> String {
        var lines = ["Base Clone 弱提示：优先保持参考音频或 clone prompt 的音色稳定；演绎风格可作为辅助提示，不承诺像 CustomVoice/VoiceDesign 一样强控制。"]
        appendLine("语言与口音", pairs: [
            ("语言", profile.language),
            ("口音", profile.accent)
        ], to: &lines)
        appendLine("弱演绎提示", pairs: [
            ("语速", profile.speed),
            ("音量", profile.volume),
            ("情绪", profile.emotion),
            ("语调", profile.tone),
            ("清晰度", profile.clarity)
        ], to: &lines)
        appendLine("约束", values: [profile.negativePrompt], to: &lines)
        appendLine("补充指令", values: [profile.customPrompt], to: &lines)
        return lines.joined(separator: "\n")
    }

    private static func appendLine(_ title: String, values: [String], to lines: inout [String]) {
        let content = values.map(\.trimmed).filter { !$0.isEmpty }.joined(separator: "，")
        guard !content.isEmpty else { return }
        lines.append("\(title)：\(content)。")
    }

    private static func appendLine(_ title: String, pairs: [(String, String)], to lines: inout [String]) {
        let content = pairs
            .map { ($0.0, $0.1.trimmed) }
            .filter { !$0.1.isEmpty }
            .map(\.1)
            .joined(separator: "，")
        guard !content.isEmpty else { return }
        lines.append("\(title)：\(content)。")
    }
}

public struct VoiceControlPreset: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var title: String
    public var category: VoiceControlCategory
    public var profile: VoiceControlProfile
    private static let regionalDialects: Set<String> = ["北京话", "四川话", "粤语", "上海话"]

    public init(
        id: String,
        title: String,
        category: VoiceControlCategory = .general,
        profile: VoiceControlProfile
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.profile = profile
    }

    public func applying(to base: VoiceControlProfile) -> VoiceControlProfile {
        VoiceControlProfile(
            roleName: merged(profile.roleName, base.roleName),
            language: merged(profile.language, base.language),
            dialect: merged(profile.dialect, base.dialect),
            age: merged(profile.age, base.age),
            genderPresentation: merged(profile.genderPresentation, base.genderPresentation),
            pitch: merged(profile.pitch, base.pitch),
            speed: merged(profile.speed, base.speed),
            volume: merged(profile.volume, base.volume),
            clarity: merged(profile.clarity, base.clarity),
            fluency: merged(profile.fluency, base.fluency),
            accent: merged(profile.accent, base.accent),
            emotion: merged(profile.emotion, base.emotion),
            tone: merged(profile.tone, base.tone),
            persona: merged(profile.persona, base.persona),
            acousticTexture: merged(profile.acousticTexture, base.acousticTexture),
            humanLikeness: merged(profile.humanLikeness, base.humanLikeness),
            background: merged(profile.background, base.background),
            gradient: merged(profile.gradient, base.gradient),
            negativePrompt: merged(profile.negativePrompt, base.negativePrompt),
            customPrompt: merged(profile.customPrompt, base.customPrompt)
        )
    }

    public var requiresCustomVoiceModel: Bool {
        category == .multilingualDialect || Self.regionalDialects.contains(profile.dialect.trimmed)
    }

    public static let acousticAnnouncer = VoiceControlPreset(
        id: "official-acoustic-announcer",
        title: "声学属性",
        category: .acousticAttributes,
        profile: VoiceControlProfile(
            roleName: "纪录片旁白",
            language: "中文",
            dialect: "普通话",
            age: "30岁左右",
            genderPresentation: "女性声线",
            pitch: "中低音",
            speed: "语速适中",
            volume: "音量稳定",
            clarity: "吐字清楚",
            fluency: "句间停顿自然",
            emotion: "平静可信赖",
            tone: "客观、温和",
            acousticTexture: "温暖、沉稳、略带气声"
        )
    )

    public static let childlikeAge = VoiceControlPreset(
        id: "official-age-childlike",
        title: "年龄身份",
        category: .ageIdentity,
        profile: VoiceControlProfile(
            roleName: "好奇少年",
            age: "少年",
            genderPresentation: "年轻清亮声线",
            pitch: "中高音",
            speed: "语速略快",
            clarity: "吐字清晰但保留年轻感",
            emotion: "好奇、轻快",
            persona: "第一次接触新知识的学生"
        )
    )

    public static let emotionalActing = VoiceControlPreset(
        id: "official-emotion-acting",
        title: "情绪表演",
        category: .emotionActing,
        profile: VoiceControlProfile(
            roleName: "内心独白者",
            speed: "语速时快时慢",
            volume: "音量随情绪轻微起伏",
            emotion: "紧张、克制，偶尔泄露不安",
            tone: "从自我怀疑到逐渐坚定",
            humanLikeness: "保留短暂停顿、轻微吸气和犹豫感",
            background: "人物正在讲述一个压力很大的转折时刻"
        )
    )

    public static let gradientOutburst = VoiceControlPreset(
        id: "official-gradient-outburst",
        title: "渐变控制",
        category: .gradientControl,
        profile: VoiceControlProfile(
            speed: "开头慢速，随后逐渐加快",
            volume: "开头偏低，结尾明显增强",
            emotion: "先压抑后爆发",
            gradient: "开头平稳克制，中段逐渐加快并增强紧张感，结尾留出短暂停顿",
            negativePrompt: "避免一开始就过度激动"
        )
    )

    public static let personaScientist = VoiceControlPreset(
        id: "official-persona-scientist",
        title: "角色背景",
        category: .personaBackground,
        profile: VoiceControlProfile(
            roleName: "林怀岳",
            language: "中文",
            dialect: "普通话",
            age: "年近七十",
            genderPresentation: "男性低沉声线",
            pitch: "低沉稳定",
            speed: "语速平稳",
            volume: "洪亮有力度",
            clarity: "吐字清晰",
            fluency: "表达流畅，一气呵成",
            emotion: "严肃坚定，带历史担当",
            tone: "权威、克制、富有感染力",
            persona: "资深战略科学家",
            acousticTexture: "浑厚，略带沙哑感",
            humanLikeness: "保留自然呼吸和关键停顿",
            background: "长期参与国家重点科研项目，正在向年轻工程师解释关键技术选择",
            negativePrompt: "避免卡通化和夸张表演"
        )
    )

    public static let conversationalHuman = VoiceControlPreset(
        id: "official-human-chatty",
        title: "拟人感",
        category: .humanLikeness,
        profile: VoiceControlProfile(
            roleName: "朋友式讲述者",
            speed: "语速自然，偶尔放慢",
            emotion: "亲近、自然、带轻微笑意",
            tone: "像面对面聊天",
            humanLikeness: "加入自然停顿、轻微笑声、犹豫和换气感",
            negativePrompt: "不要像播报机器一样平铺直叙"
        )
    )

    public static let dialectSichuan = VoiceControlPreset(
        id: "official-dialect-sichuan",
        title: "方言控制",
        category: .multilingualDialect,
        profile: VoiceControlProfile(
            language: "中文",
            dialect: "四川话",
            accent: "自然四川口音",
            emotion: "亲切、松弛、带口语感",
            persona: "生活化的四川本地说话者"
        )
    )

    public static let multiRoleDialogue = VoiceControlPreset(
        id: "official-multi-role-dialogue",
        title: "多角色",
        category: .timbreReuse,
        profile: VoiceControlProfile(
            customPrompt: """
            为合成文本中的角色分别建立音色：旁白=沉稳客观、略带叙事感；小林=25岁男性上班族，清亮但紧张；御姐=成熟磁性女性声线，沉稳自信、略带挑逗。
            遇到角色名前缀时切换到对应音色，并保持每个角色在整段对话中稳定。
            """
        )
    )

    public static let naturalNarration = VoiceControlPreset(
        id: "natural-narration",
        title: "自然旁白",
        category: .acousticAttributes,
        profile: VoiceControlProfile(
            dialect: "普通话",
            speed: "语速自然",
            volume: "音量中等",
            clarity: "吐字清楚",
            fluency: "停顿自然，表达连贯",
            emotion: "自然、清晰、稳定",
            acousticTexture: "温暖、克制、适合旁白"
        )
    )

    public static let emotionalNarration = VoiceControlPreset(
        id: "emotional-narration",
        title: "情绪更强",
        category: .emotionActing,
        profile: VoiceControlProfile(
            emotion: "情绪更饱满，语气有感染力",
            tone: "重点词更有画面感",
            acousticTexture: "句尾保留自然气息",
            gradient: "从平稳叙述逐渐增强情绪"
        )
    )

    public static let slowClear = VoiceControlPreset(
        id: "slow-clear",
        title: "慢速清晰",
        category: .acousticAttributes,
        profile: VoiceControlProfile(
            speed: "语速偏慢",
            volume: "音量中等",
            clarity: "吐字非常清楚",
            fluency: "停顿更明显",
            emotion: "耐心、平稳"
        )
    )

    public static let characterPersona = VoiceControlPreset(
        id: "character-persona",
        title: "角色化",
        category: .personaBackground,
        profile: VoiceControlProfile(
            emotion: "有画面感，但不过度夸张",
            persona: "有明确角色感的说话者",
            humanLikeness: "更像真人对话，带自然呼吸和情绪起伏"
        )
    )

    public static let beijingDialogue = VoiceControlPreset(
        id: "beijing-dialogue",
        title: "北京话",
        category: .multilingualDialect,
        profile: VoiceControlProfile(
            language: "中文",
            dialect: "北京话",
            accent: "自然北京口音",
            emotion: "自然口语化",
            persona: "生活化的北京本地说话者"
        )
    )

    public static let gradualTension = VoiceControlPreset(
        id: "gradual-tension",
        title: "渐变紧张",
        category: .gradientControl,
        profile: VoiceControlProfile(
            speed: "语速从自然逐渐变快",
            emotion: "紧张但克制",
            gradient: "开头平稳克制，中段逐渐加快并增强紧张感，结尾留出短暂停顿"
        )
    )

    public static let sichuanDialogue = VoiceControlPreset(
        id: "sichuan-dialogue",
        title: "四川话",
        category: .multilingualDialect,
        profile: VoiceControlProfile(
            language: "中文",
            dialect: "四川话",
            accent: "自然四川口音",
            emotion: "亲切、松弛、带口语感",
            persona: "生活化的四川本地说话者"
        )
    )

    public static let barScene = VoiceControlPreset(
        id: "bar-scene",
        title: "酒吧场景",
        category: .emotionActing,
        profile: VoiceControlProfile(
            volume: "音量偏低",
            emotion: "暧昧、克制、带一点试探",
            tone: "靠近、轻声、留有余韵",
            acousticTexture: "贴近耳边的自然说话感",
            background: "酒吧灯光昏黄，环境私密，人物低声交谈"
        )
    )

    public static let recommendedForVoiceDesign: [VoiceControlPreset] = [
        .acousticAnnouncer,
        .childlikeAge,
        .emotionalActing,
        .gradientOutburst,
        .personaScientist,
        .conversationalHuman
    ]

    public static let recommendedForMultiRoleDialogue: [VoiceControlPreset] = [
        .multiRoleDialogue
    ]

    public static let recommendedForScriptStudio: [VoiceControlPreset] = [
        .naturalNarration,
        .emotionalNarration,
        .slowClear,
        .characterPersona,
        .beijingDialogue,
        .sichuanDialogue,
        .gradualTension,
        .barScene
    ]

    public static func recommendedForScriptStudio(workflow: ScriptStudioWorkflow) -> [VoiceControlPreset] {
        switch workflow {
        case .builtin:
            return recommendedForScriptStudio
        case .custom, .voiceDesign, .multiRole:
            return recommendedForScriptStudio.filter { !$0.requiresCustomVoiceModel }
        }
    }
}

private func merged(_ preferred: String, _ fallback: String) -> String {
    preferred.trimmed.isEmpty ? fallback : preferred
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
