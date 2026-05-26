import Foundation

public enum VoiceInstructionWorkflow: String, Codable, CaseIterable, Hashable, Sendable {
    case customVoice
    case voiceDesign
}

public struct VoiceInstructionTemplate: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var workflow: VoiceInstructionWorkflow
    public var tags: [String]
    public var instruction: String

    public init(
        id: String,
        title: String,
        workflow: VoiceInstructionWorkflow,
        tags: [String] = [],
        instruction: String
    ) {
        self.id = id
        self.title = title
        self.workflow = workflow
        self.tags = tags
        self.instruction = instruction
    }
}

public struct VoiceInstructionDraftState: Equatable, Sendable {
    public private(set) var value: String
    public private(set) var didAutoInitialize: Bool
    public private(set) var wasEditedByUser: Bool

    public init(value: String = "", didAutoInitialize: Bool = false, wasEditedByUser: Bool = false) {
        self.value = value
        self.didAutoInitialize = didAutoInitialize
        self.wasEditedByUser = wasEditedByUser
    }

    @discardableResult
    public mutating func initializeIfNeeded(with template: VoiceInstructionTemplate) -> Bool {
        guard !didAutoInitialize, !wasEditedByUser, value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        value = template.instruction
        didAutoInitialize = true
        return true
    }

    public mutating func applyUserEdit(_ instruction: String) {
        value = instruction
        wasEditedByUser = true
    }
}

public enum VoiceInstructionLibrary {
    public static func templates(for workflow: VoiceInstructionWorkflow) -> [VoiceInstructionTemplate] {
        allTemplates.filter { $0.workflow == workflow }
    }

    public static func randomTemplate(
        for workflow: VoiceInstructionWorkflow,
        using generator: inout some RandomNumberGenerator
    ) -> VoiceInstructionTemplate? {
        templates(for: workflow).randomElement(using: &generator)
    }

    public static func randomTemplate(for workflow: VoiceInstructionWorkflow) -> VoiceInstructionTemplate? {
        var generator = SystemRandomNumberGenerator()
        return randomTemplate(for: workflow, using: &generator)
    }

    public static func randomInstruction(for workflow: VoiceInstructionWorkflow) -> String {
        randomTemplate(for: workflow)?.instruction ?? ""
    }

    public static let allTemplates: [VoiceInstructionTemplate] = customVoiceTemplates + voiceDesignTemplates

    private static let customVoiceTemplates: [VoiceInstructionTemplate] = [
        template("custom-calm-narrator", "沉稳旁白", .customVoice, ["旁白", "冷静"], "在当前 speaker 音色基础上保持普通话清晰稳定，语速适中，情绪冷静旁观，关键情节前稍作停顿，整体有纪录片旁白的叙事感。"),
        template("custom-warm-science", "温和科普", .customVoice, ["科普"], "语速自然，吐字清楚，音量中等，情绪温和可信，解释复杂概念时放慢关键词，不夸张表演。"),
        template("custom-urgent-news", "紧迫播报", .customVoice, ["新闻"], "保持当前音色身份，语速略快但不含混，音量稳定偏强，情绪克制紧迫，句尾干净收束。"),
        template("custom-soft-story", "轻柔叙事", .customVoice, ["故事"], "声音柔和，语速偏慢，保留自然换气和轻微停顿，情绪带一点温度，适合睡前故事或回忆旁白。"),
        template("custom-ironic-observer", "微讽观察", .customVoice, ["反讽"], "语调平缓，情绪冷静旁观，在反讽句上轻微压低语气，关键短句后停顿，不破坏原文严肃感。"),
        template("custom-dialogue-natural", "自然对话", .customVoice, ["对话"], "像真人对话一样自然，语速有轻微起伏，重点词清楚，疑问句自然上扬，避免机械朗读。"),
        template("custom-emotional-restraint", "克制情绪", .customVoice, ["情绪"], "整体保持克制，情绪只在关键句略微增强，音量不突然放大，停顿服务于画面感。"),
        template("custom-clear-training", "教学清晰", .customVoice, ["教学"], "吐字非常清楚，语速中慢，公式、数字和专有名词放慢，语气耐心稳定。"),
        template("custom-documentary-wide", "宏大纪录片", .customVoice, ["纪录片"], "使用开阔、沉稳、有距离感的叙事方式，音量稳定，语速适中，段落之间留出自然停顿。"),
        template("custom-live-sales", "销售紧张感", .customVoice, ["销售"], "语速偏快，音量更有推动力，情绪积极有感染力，但保持当前 speaker 音色，不要过度尖锐。"),
        template("custom-whisper-close", "贴近低声", .customVoice, ["低声"], "音量偏低，语气贴近耳边，语速自然，保留轻微气声和短暂停顿，避免听不清。"),
        template("custom-firm-command", "坚定指令", .customVoice, ["指令"], "语气坚定，节奏干净，重点动词加重，音量中高，情绪不拖沓。"),
        template("custom-comedic-light", "轻喜剧", .customVoice, ["喜剧"], "保持轻松口语感，语速略快，包袱前稍作停顿，反应句自然但不过分夸张。"),
        template("custom-sad-muted", "低落克制", .customVoice, ["悲伤"], "语速偏慢，音量偏低，情绪低落但克制，句尾轻微下沉，避免哭腔过重。"),
        template("custom-suspense", "悬疑推进", .customVoice, ["悬疑"], "语调压低，停顿更明显，语速由慢到自然，关键线索读得清楚，营造悬疑感。"),
        template("custom-bright-youth", "年轻明亮", .customVoice, ["年轻"], "语速自然偏快，音色保持明亮，情绪积极，句间衔接轻快但不抢拍。"),
        template("custom-formal-business", "商务正式", .customVoice, ["商务"], "表达正式、清楚、客观，语速适中，音量稳定，数字和结论重点突出。"),
        template("custom-gentle-companion", "陪伴口吻", .customVoice, ["陪伴"], "语气亲近、放松，语速适中偏慢，保留轻微笑意，避免过度表演。"),
        template("custom-epic-trailer", "预告片", .customVoice, ["预告"], "节奏有推进感，音量逐步增强，短句更有力度，结尾留出悬念停顿。"),
        template("custom-neutral-audiobook", "长篇有声书", .customVoice, ["有声书"], "长段落保持稳定，语速中等，角色对白和旁白有轻微区分，情绪跟随文本但不失控。")
    ]

    private static let voiceDesignTemplates: [VoiceInstructionTemplate] = [
        template("design-calm-female-documentary", "女声纪录片", .voiceDesign, ["旁白"], "30岁左右女性纪录片旁白，普通话标准，中低音，声音沉稳客观，略带叙事感；语速适中，音量稳定，关键情节前有短暂停顿。"),
        template("design-aged-scientist", "老年科学家", .voiceDesign, ["角色"], "年近七十的男性战略科学家，低沉浑厚，吐字清晰，语速平稳，背景是长期参与重大科研项目，语气权威克制但有感染力。"),
        template("design-child-curious", "好奇少年", .voiceDesign, ["年龄"], "少年声线，音调中高，语速略快，情绪好奇轻快，像第一次接触新知识的学生，保留自然兴奋感。"),
        template("design-infomercial", "电视购物", .voiceDesign, ["声学"], "中年男性电视购物主持人，声音洪亮有激情，语速极快，音调夸张上扬，语气极具煽动性，营造紧迫抢购氛围。"),
        template("design-sad-hoarse", "悲苦沙哑", .voiceDesign, ["情绪"], "30岁左右男性，声音悲苦沙哑，语速偏慢，情绪浓烈带轻微哭腔，语调哀怨高亢，音高起伏大。"),
        template("design-human-chat", "拟人闲聊", .voiceDesign, ["拟人"], "朋友式讲述者，语速自然，带轻微笑意，保留换气、犹豫和短暂停顿，像面对面聊天而不是播报。"),
        template("design-bar-low", "酒吧低声", .voiceDesign, ["背景"], "成熟磁性女性声线，音量偏低，语气靠近、克制、留有余韵，背景是昏黄酒吧里的低声交谈。"),
        template("design-space-bridge", "太空舰桥", .voiceDesign, ["科幻"], "冷静女舰长声线，中低音，语速稳定，背景是太空舰桥的低频环境声，语气克制、明确、带指挥感。"),
        template("design-gradient-tension", "渐变紧张", .voiceDesign, ["渐变"], "开头平稳克制，中段语速逐渐加快并增强紧张感，结尾收束为短促停顿，避免一开始过度激动。"),
        template("design-warm-teacher", "温暖教师", .voiceDesign, ["教学"], "35岁女性教师，温暖耐心，语速中慢，音量中等，复杂术语放慢，情绪稳定可信。"),
        template("design-young-reporter", "年轻记者", .voiceDesign, ["新闻"], "年轻男性现场记者，清亮中音，语速偏快，吐字清楚，背景是嘈杂新闻现场但人声突出，情绪紧迫但专业。"),
        template("design-ancient-narrator", "史诗旁白", .voiceDesign, ["史诗"], "中年男性低沉旁白，音色厚重，语速偏慢，音量逐渐增强，背景有历史叙事感，关键名词有庄重停顿。"),
        template("design-cyber-host", "赛博主持", .voiceDesign, ["科技"], "中性科技节目主持声线，清晰、冷静、节奏精准，音色干净略带未来感，适合解释 AI 和工程系统。"),
        template("design-nervous-student", "紧张学生", .voiceDesign, ["角色"], "17岁男性学生，男高音偏紧，刚开始紧张犹豫，呼吸较浅，中段逐渐获得信心但元音仍略紧。"),
        template("design-mature-mentor", "成熟导师", .voiceDesign, ["导师"], "45岁女性导师，成熟稳重，中低音，语速自然，语气包容但有边界，适合给出冷静建议。"),
        template("design-radio-night", "夜间电台", .voiceDesign, ["电台"], "夜间电台女主播，声音柔和低缓，轻微气声，语速偏慢，背景氛围安静，句尾自然下沉。"),
        template("design-legal-neutral", "法律客观", .voiceDesign, ["正式"], "中年中性声线，普通话标准，语气客观审慎，语速中等，条款和事实读得清楚，不加入过多情绪。"),
        template("design-adventure-kid", "冒险儿童", .voiceDesign, ["儿童"], "8岁左右儿童声线，音调偏高，情绪兴奋好奇，语速略快，适合动画冒险角色，避免过度尖叫。"),
        template("design-villain-calm", "冷静反派", .voiceDesign, ["角色"], "低沉男性反派声线，语速慢而稳定，音量不高但压迫感强，微妙反讽，关键句前有冷静停顿。"),
        template("design-medical-soft", "医疗安抚", .voiceDesign, ["安抚"], "专业医疗咨询女声，清晰、温和、低刺激，语速中慢，避免夸张情绪，给人稳定和可信赖感。")
    ]

    private static func template(
        _ id: String,
        _ title: String,
        _ workflow: VoiceInstructionWorkflow,
        _ tags: [String],
        _ instruction: String
    ) -> VoiceInstructionTemplate {
        VoiceInstructionTemplate(id: id, title: title, workflow: workflow, tags: tags, instruction: instruction)
    }
}
