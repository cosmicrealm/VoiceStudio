import Foundation

public extension VoiceInstructionLibrary {
    static func templates(for workflow: VoiceInstructionWorkflow, language: AppLanguage) -> [VoiceInstructionTemplate] {
        switch AppLanguage.resolved(language) {
        case .simplifiedChinese:
            return templates(for: workflow)
        case .traditionalChinese:
            return localizedTemplates(
                workflow: workflow,
                languageCode: "zh-Hant",
                titles: workflow == .customVoice
                    ? ["沉穩旁白", "溫和科普", "自然對話"]
                    : ["女聲紀錄片", "成熟導師", "夜間電台"],
                instructions: workflow == .customVoice
                    ? [
                        "在目前 speaker 音色基礎上保持中文清晰穩定，語速適中，情緒冷靜旁觀，關鍵情節前稍作停頓，整體有紀錄片旁白的敘事感。",
                        "語速自然，吐字清楚，音量中等，情緒溫和可信，解釋複雜概念時放慢關鍵詞，不誇張表演。",
                        "像真人對話一樣自然，語速有輕微起伏，重點詞清楚，疑問句自然上揚，避免機械朗讀。"
                    ]
                    : [
                        "30歲左右女性紀錄片旁白，中文標準，中低音，聲音沉穩客觀，略帶敘事感；語速適中，音量穩定，關鍵情節前有短暫停頓。",
                        "45歲女性導師，成熟穩重，中低音，語速自然，語氣包容但有邊界，適合給出冷靜建議。",
                        "夜間電台女主播，聲音柔和低緩，輕微氣聲，語速偏慢，背景氛圍安靜，句尾自然下沉。"
                    ]
            )
        case .english:
            return localizedTemplates(
                workflow: workflow,
                languageCode: "en",
                titles: workflow == .customVoice
                    ? ["Calm Narrator", "Warm Explainer", "Natural Dialogue"]
                    : ["Female Documentary", "Mature Mentor", "Late-Night Radio"],
                instructions: workflow == .customVoice
                    ? [
                        "Keep the current speaker timbre clear and stable, with a moderate pace, calm observer emotion, brief pauses before key plot moments, and a documentary narration feel.",
                        "Use a natural pace, clear articulation, medium volume, and a warm trustworthy tone; slow down key terms when explaining complex ideas without overacting.",
                        "Speak like a real conversation, with slight rhythm changes, clear key words, naturally rising questions, and no mechanical reading."
                    ]
                    : [
                        "A female documentary narrator around thirty, standard clear pronunciation, medium-low pitch, calm and objective with a light narrative feel; moderate pace, stable volume, and short pauses before key moments.",
                        "A mature female mentor around forty-five, steady medium-low voice, natural pace, inclusive but bounded tone, suitable for calm advice.",
                        "A late-night radio female host, soft and low, slightly breathy, slow pace, quiet ambience, and naturally falling sentence endings."
                    ]
            )
        case .japanese:
            return localizedTemplates(
                workflow: workflow,
                languageCode: "ja",
                titles: workflow == .customVoice ? ["落ち着いたナレーター", "温かい解説", "自然な会話"] : ["女性ドキュメンタリー", "成熟したメンター", "深夜ラジオ"],
                instructions: workflow == .customVoice
                    ? [
                        "現在の speaker の声質を保ちながら、発音を明瞭で安定させ、速度は中程度、感情は冷静な観察者として、重要な場面の前に短い間を置きます。",
                        "自然な速度、明瞭な発音、中程度の音量、温かく信頼できる語り口で、複雑な概念では重要語をゆっくり読みます。",
                        "実際の会話のように自然に、リズムに小さな起伏をつけ、重要語を明瞭にし、疑問文は自然に上げます。"
                    ]
                    : [
                        "30歳前後の女性ドキュメンタリー語り手。明瞭な発音、中低音、冷静で客観的、少し物語性があり、速度は中程度です。",
                        "45歳前後の女性メンター。成熟して落ち着いた中低音、自然な速度、包容力がありつつ境界のある語り口です。",
                        "深夜ラジオの女性パーソナリティ。柔らかく低め、わずかに息を含み、ゆっくりした速度で静かな雰囲気です。"
                    ]
            )
        case .korean:
            return localizedTemplates(
                workflow: workflow,
                languageCode: "ko",
                titles: workflow == .customVoice ? ["차분한 내레이터", "따뜻한 해설자", "자연스러운 대화"] : ["여성 다큐멘터리", "성숙한 멘토", "심야 라디오"],
                instructions: workflow == .customVoice
                    ? [
                        "현재 speaker의 음색을 유지하면서 발음을 또렷하고 안정적으로 하고, 속도는 중간 정도로, 감정은 차분한 관찰자처럼 유지합니다.",
                        "자연스러운 속도, 또렷한 발음, 중간 음량, 따뜻하고 신뢰감 있는 톤으로 복잡한 개념의 핵심어를 천천히 읽습니다.",
                        "실제 대화처럼 자연스럽게 말하고 리듬에 약간의 변화와 명확한 핵심어, 자연스러운 질문 억양을 유지합니다."
                    ]
                    : [
                        "30대 여성 다큐멘터리 내레이터, 또렷한 발음, 중저음, 차분하고 객관적이며 약간의 서사감을 가집니다.",
                        "45세 여성 멘토, 성숙하고 안정적인 중저음, 자연스러운 속도, 포용적이지만 분명한 어조입니다.",
                        "심야 라디오 여성 진행자, 부드럽고 낮으며 약간의 숨소리가 있고 천천히 말합니다."
                    ]
            )
        default:
            return templates(for: workflow, language: .english)
        }
    }

    static func randomTemplate(
        for workflow: VoiceInstructionWorkflow,
        using generator: inout some RandomNumberGenerator,
        language: AppLanguage
    ) -> VoiceInstructionTemplate? {
        templates(for: workflow, language: language).randomElement(using: &generator)
    }

    static func randomTemplate(for workflow: VoiceInstructionWorkflow, language: AppLanguage) -> VoiceInstructionTemplate? {
        var generator = SystemRandomNumberGenerator()
        return randomTemplate(for: workflow, using: &generator, language: language)
    }

    static func randomInstruction(for workflow: VoiceInstructionWorkflow, language: AppLanguage) -> String {
        randomTemplate(for: workflow, language: language)?.instruction ?? ""
    }

    private static func localizedTemplates(
        workflow: VoiceInstructionWorkflow,
        languageCode: String,
        titles: [String],
        instructions: [String]
    ) -> [VoiceInstructionTemplate] {
        zip(titles, instructions).enumerated().map { index, pair in
            VoiceInstructionTemplate(
                id: "\(workflow.rawValue)-\(languageCode)-\(index + 1)",
                title: pair.0,
                workflow: workflow,
                tags: [],
                instruction: pair.1
            )
        }
    }
}
