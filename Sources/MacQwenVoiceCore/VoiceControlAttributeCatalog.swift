import Foundation

public enum VoiceControlAttributeID: String, Codable, CaseIterable, Hashable, Sendable {
    case roleName
    case language
    case dialect
    case age
    case genderPresentation
    case pitch
    case speed
    case volume
    case clarity
    case fluency
    case accent
    case emotion
    case tone
    case persona
    case acousticTexture
    case humanLikeness
    case background
    case gradient
    case negativePrompt
    case customPrompt
}

public struct VoiceControlAttributeDefinition: Codable, Equatable, Identifiable, Sendable {
    public var id: VoiceControlAttributeID
    public var title: String
    public var category: VoiceControlCategory
    public var candidates: [String]

    public init(id: VoiceControlAttributeID, title: String, category: VoiceControlCategory, candidates: [String]) {
        self.id = id
        self.title = title
        self.category = category
        self.candidates = candidates
    }
}

public enum VoiceControlAttributeCatalog {
    private static let languageNeutralAccentCandidates: [String] = [
        "标准清晰发音", "自然口语发音", "新闻播报腔", "生活化口语腔", "播音腔", "电台腔", "纪录片旁白腔", "课堂讲解腔", "朋友聊天腔", "正式汇报腔",
        "舞台叙事腔", "影视旁白腔", "沉稳低声表达", "明亮清爽表达", "柔和亲近表达", "克制客观表达", "悬疑压低表达", "安抚式表达", "紧迫播报表达", "有声书朗读腔"
    ]

    public static let definitions: [VoiceControlAttributeDefinition] = [
        definition(.roleName, "角色姓名", .personaBackground, [
            "旁白", "纪录片旁白", "新闻播报员", "夜间电台主播", "科普讲解员", "资深科学家", "年轻记者", "冷静舰长", "温暖教师", "成熟导师",
            "好奇少年", "紧张学生", "商务主持人", "法庭陈述者", "医疗咨询员", "电视购物主持人", "酒吧低声讲述者", "反派旁白", "冒险儿童", "朋友式讲述者"
        ]),
        definition(.language, "语言", .multilingualDialect, [
            "中文", "英文", "日语", "韩语", "德语", "法语", "俄语", "葡萄牙语", "西班牙语", "意大利语",
            "普通话中文", "美式英文", "英式英文", "日文", "韩文", "德文", "法文", "俄文", "葡萄牙文", "西班牙文"
        ]),
        definition(.dialect, "方言", .multilingualDialect, [
            "普通话", "北京话", "四川话", "自然普通话", "标准普通话", "轻微北方口音", "轻微南方口音", "新闻播音普通话", "生活化普通话", "口语普通话",
            "美式英语口音", "英式英语口音", "澳洲英语口音", "日语东京口音", "关西口音倾向", "首尔韩语", "德语标准口音", "法语标准口音", "俄语标准口音", "西班牙语标准口音"
        ]),
        definition(.age, "年龄", .ageIdentity, [
            "儿童", "8岁左右", "少年", "17岁左右", "20岁左右", "25岁左右", "30岁左右", "35岁左右", "40岁左右", "45岁左右",
            "中年", "50岁左右", "55岁左右", "60岁左右", "年近七十", "老年", "年轻成人", "成熟成人", "青年感", "长者感"
        ]),
        definition(.genderPresentation, "声线", .ageIdentity, [
            "女性声线", "男性声线", "中性声线", "年轻清亮声线", "成熟磁性女性声线", "男性低沉声线", "少年清亮声线", "儿童稚嫩声线", "女播音腔", "男播音腔",
            "温柔女声", "沉稳男声", "清爽青年男声", "明亮青年女声", "沙哑男声", "气声女声", "厚重低音男声", "轻盈少女声线", "成熟导师声线", "冷静指挥声线"
        ]),
        definition(.pitch, "音高", .acousticAttributes, [
            "低沉稳定", "低音", "中低音", "中音", "中高音", "高音", "音调偏高", "音调偏低", "音高起伏大", "音高起伏小",
            "句尾轻微上扬", "句尾自然下沉", "关键字音高上扬", "整体平稳少起伏", "紧张时音高升高", "克制时音高压低", "明亮高频更多", "低频厚度更明显", "高低切换自然", "避免尖锐高音"
        ]),
        definition(.speed, "语速", .acousticAttributes, [
            "语速自然", "语速适中", "语速偏慢", "语速偏快", "慢速清晰", "快速但清楚", "开头慢速，随后逐渐加快", "开头自然，结尾放慢", "句间停顿更长", "短句节奏紧凑",
            "长句保持稳定", "解释术语时放慢", "情绪增强时略快", "紧张段落加快", "回忆段落放慢", "新闻播报节奏", "口语聊天节奏", "有声书稳定节奏", "预告片推进节奏", "避免拖沓"
        ]),
        definition(.volume, "音量", .acousticAttributes, [
            "音量中等", "音量稳定", "音量偏低", "音量偏高", "洪亮有力度", "贴近低声", "开头偏低，结尾增强", "重点词略微加重", "整体不突然放大", "情绪段落轻微增强",
            "私密场景降低音量", "演讲场景提高音量", "播报音量均衡", "耳语但清楚", "远距离叙事感", "近距离口语感", "结尾收束降低音量", "转折句增强音量", "避免爆音", "避免听感过弱"
        ]),
        definition(.clarity, "清晰度", .acousticAttributes, [
            "吐字清楚", "吐字非常清楚", "重点词放慢并加强清晰度", "数字清楚", "英文单词清楚", "专有名词清楚", "公式符号放慢", "轻微口语化但不含混", "复杂标点停顿清楚", "每句起音干净",
            "句尾不吞字", "避免连读过重", "保留自然咬字", "播音级清晰度", "角色化但清楚", "低声也保持清楚", "快速语速下保持清晰", "多语言词汇清楚", "情绪强时不含混", "避免机械切字"
        ]),
        definition(.fluency, "流畅度", .acousticAttributes, [
            "表达流畅", "表达连贯", "句间停顿自然", "保留关键停顿", "一气呵成", "段落衔接平滑", "对话反应自然", "旁白节奏稳定", "长句不断裂", "短句有呼吸",
            "轻微犹豫感", "自然换气", "避免重复卡顿", "避免机械停顿", "关键情节前停顿", "反问句后留白", "转折处轻微停顿", "情绪转换自然", "语义边界清楚", "读完整句再收束"
        ]),
        definition(.accent, "口音细节", .multilingualDialect, [
            "标准普通话", "自然普通话", "轻微北京口音", "自然四川口音", "轻微北方口音", "轻微南方口音", "新闻播报腔", "生活化口语腔", "美式英语", "英式英语",
            "英语母语者口音", "英语非母语轻微口音", "东京日语口音", "自然韩语口音", "法语标准口音", "德语标准口音", "俄语标准口音", "葡萄牙语标准口音", "西班牙语标准口音", "意大利语标准口音"
        ]),
        definition(.emotion, "情绪", .emotionActing, [
            "平静可信赖", "温柔、清晰、自然", "严肃坚定", "紧张但克制", "亲近自然", "轻微笑意", "悲伤克制", "愤怒压抑", "兴奋明亮", "好奇轻快",
            "先压抑后爆发", "冷静旁观", "微妙反讽", "焦虑不安", "怀旧温暖", "庄重肃穆", "暧昧克制", "安抚稳定", "权威笃定", "悬疑紧绷"
        ]),
        definition(.tone, "语调", .emotionActing, [
            "客观平稳", "温和叙事", "权威克制", "口语自然", "新闻播报", "纪录片叙事", "夜间电台", "轻微反讽", "靠近低声", "清亮明快",
            "庄重缓慢", "紧迫推进", "疑问自然上扬", "结论句下沉", "转折句加重", "情绪逐渐增强", "安抚式语调", "指挥式语调", "悬疑压低", "预告片式留白"
        ]),
        definition(.persona, "角色 / persona", .personaBackground, [
            "资深战略科学家", "冷静纪录片旁白", "新闻现场记者", "温暖科普老师", "夜间电台主播", "成熟心理咨询师", "年轻上班族", "紧张学生", "太空舰长", "商务主持人",
            "法庭陈述者", "医疗咨询员", "电视购物主持人", "朋友式讲述者", "冷静反派", "冒险儿童", "历史讲述者", "产品经理", "工程师讲解员", "故事旁白"
        ]),
        definition(.acousticTexture, "音色质感", .acousticAttributes, [
            "温暖沉稳", "低沉浑厚", "清亮干净", "略带气声", "轻微沙哑", "磁性柔和", "明亮有颗粒感", "厚重低频", "干净无混响", "贴近耳边",
            "开阔叙事感", "广播质感", "电台质感", "自然真人感", "清爽年轻感", "成熟稳重感", "悲苦沙哑感", "甜美轻盈感", "冷静科技感", "避免金属感"
        ]),
        definition(.humanLikeness, "拟人感", .humanLikeness, [
            "保留自然换气和轻微停顿", "加入短暂犹豫", "轻微笑声感", "句前自然吸气", "说话像面对面聊天", "重点句前留白", "情绪转换有呼吸", "低声也自然", "避免机器播报", "保留口语节奏",
            "不过度平滑", "轻微吞吐但不影响清晰", "自然反应速度", "疑问句像真实提问", "感叹句不过度夸张", "结尾自然收束", "段落间有人声间隔", "保留临场感", "像真人旁白", "避免合成腔"
        ]),
        definition(.background, "背景信息", .personaBackground, [
            "安静录音棚", "夜间电台直播间", "太空舰桥的低频环境声", "新闻发布会现场", "昏黄酒吧角落", "大学课堂", "医院咨询室", "法庭陈述现场", "纪录片外景旁白", "办公室会议室",
            "雨夜车内", "城市清晨街道", "老旧实验室", "儿童动画场景", "商业路演现场", "历史档案馆", "科幻控制室", "心理咨询室", "产品发布会", "深夜独白空间"
        ]),
        definition(.gradient, "渐变控制", .gradientControl, [
            "开头平稳，中段逐渐增强，结尾收束", "开头慢速，随后逐渐加快", "情绪从克制到坚定", "音量从低到中高", "紧张感逐步上升", "从轻松到严肃", "从疑惑到确认", "从冷静到轻微激动", "结尾留出短暂停顿", "关键句前突然放慢",
            "第一句低声，后面恢复自然", "中段加入压迫感", "末尾语气下沉", "转折后语速变快", "解释段落放慢", "高潮段落增强音量", "对话反应逐渐自然", "从旁观到投入", "从微笑到克制", "避免一开始过度表演"
        ]),
        definition(.negativePrompt, "约束", .general, [
            "避免卡通化", "避免过度表演", "避免机械播报", "不要改变当前 speaker 的基本音色", "不要生成尖锐高音", "不要吞字", "不要拖沓", "不要突然爆音", "不要过度哭腔", "不要过度卖萌",
            "不要朗读角色名", "不要朗读舞台说明", "不要加入原文没有的笑声", "不要过强背景噪声", "不要破坏普通话清晰度", "不要像广告腔", "不要夸张方言", "不要过度低沉导致听不清", "不要改变文本语义", "不要省略关键词"
        ]),
        definition(.customPrompt, "补充指令", .general, [
            "关键名词放慢并加强清晰度", "每段结尾自然收束", "保持长段落稳定", "角色对白与旁白轻微区分", "数字和英文单词读清楚", "反讽句轻微压低语气", "悬疑句后留白", "解释术语时更耐心", "高能句不爆音", "保留自然口语感",
            "不要朗读括号说明", "按中文语义断句", "混合语言时保持自然切换", "适合短视频旁白", "适合长篇有声书", "适合科普讲解", "适合多角色短剧", "适合产品演示", "适合正式汇报", "适合沉浸式叙事"
        ])
    ]

    public static func definition(for id: VoiceControlAttributeID) -> VoiceControlAttributeDefinition? {
        definitions.first { $0.id == id }
    }

    public static func definitions(for workflow: ScriptStudioWorkflow) -> [VoiceControlAttributeDefinition] {
        switch workflow {
        case .builtin:
            return definitions
        case .custom, .voiceDesign, .multiRole:
            return definitions.filter { $0.id != .dialect }
        }
    }

    public static func candidates(for id: VoiceControlAttributeID) -> [String] {
        definition(for: id)?.candidates ?? []
    }

    public static func candidates(for id: VoiceControlAttributeID, workflow: ScriptStudioWorkflow) -> [String] {
        guard id != .dialect || workflow == .builtin else {
            return []
        }
        if id == .accent, workflow == .voiceDesign {
            return languageNeutralAccentCandidates
        }
        return candidates(for: id)
    }

    private static func definition(
        _ id: VoiceControlAttributeID,
        _ title: String,
        _ category: VoiceControlCategory,
        _ candidates: [String]
    ) -> VoiceControlAttributeDefinition {
        VoiceControlAttributeDefinition(id: id, title: title, category: category, candidates: candidates)
    }
}
