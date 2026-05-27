import Foundation

public extension VoiceControlCategory {
    func title(language: AppLanguage) -> String {
        switch AppLanguage.resolved(language) {
        case .english:
            switch self {
            case .general: "General"
            case .acousticAttributes: "Acoustic Attributes"
            case .ageIdentity: "Age / Identity"
            case .emotionActing: "Emotion / Acting"
            case .gradientControl: "Gradient Control"
            case .personaBackground: "Persona / Background"
            case .humanLikeness: "Human Likeness"
            case .multilingualDialect: "Language / Accent"
            case .timbreReuse: "Voice Reuse"
            }
        case .traditionalChinese:
            switch self {
            case .general: "通用"
            case .acousticAttributes: "聲學屬性"
            case .ageIdentity: "年齡/身分"
            case .emotionActing: "情緒表演"
            case .gradientControl: "漸變控制"
            case .personaBackground: "角色背景"
            case .humanLikeness: "擬人感"
            case .multilingualDialect: "語言/口音"
            case .timbreReuse: "音色復用"
            }
        case .simplifiedChinese:
            title
        default:
            title(language: .english)
        }
    }
}

public extension VoiceControlAttributeCatalog {
    static func definitions(for workflow: ScriptStudioWorkflow, language: AppLanguage) -> [VoiceControlAttributeDefinition] {
        let localized = localizedDefinitions(language: language)
        switch workflow {
        case .builtin:
            return localized
        case .custom, .voiceDesign, .multiRole:
            return localized.filter { $0.id != .dialect }
        }
    }

    static func candidates(
        for id: VoiceControlAttributeID,
        workflow: ScriptStudioWorkflow,
        language: AppLanguage
    ) -> [String] {
        guard id != .dialect || workflow == .builtin else {
            return []
        }
        if id == .accent, workflow == .voiceDesign {
            return neutralAccentCandidates(language: language)
        }
        return localizedDefinitions(language: language).first { $0.id == id }?.candidates ?? []
    }

    static func localizedDefinitions(language: AppLanguage) -> [VoiceControlAttributeDefinition] {
        switch AppLanguage.resolved(language) {
        case .simplifiedChinese:
            return definitions
        case .traditionalChinese:
            return definitions.map { definition in
                VoiceControlAttributeDefinition(
                    id: definition.id,
                    title: traditionalTitle(for: definition.id),
                    category: definition.category,
                    candidates: definition.candidates.map(traditionalizedCandidate)
                )
            }
        default:
            return definitions.map { definition in
                VoiceControlAttributeDefinition(
                    id: definition.id,
                    title: englishTitle(for: definition.id),
                    category: definition.category,
                    candidates: englishCandidates(for: definition.id)
                )
            }
        }
    }

    private static func englishTitle(for id: VoiceControlAttributeID) -> String {
        switch id {
        case .roleName: "Role Name"
        case .language: "Language"
        case .dialect: "Dialect"
        case .age: "Age"
        case .genderPresentation: "Voice Type"
        case .pitch: "Pitch"
        case .speed: "Pace"
        case .volume: "Volume"
        case .clarity: "Clarity"
        case .fluency: "Fluency"
        case .accent: "Accent Detail"
        case .emotion: "Emotion"
        case .tone: "Tone"
        case .persona: "Persona"
        case .acousticTexture: "Voice Texture"
        case .humanLikeness: "Human Likeness"
        case .background: "Background"
        case .gradient: "Gradient Control"
        case .negativePrompt: "Constraints"
        case .customPrompt: "Additional Direction"
        }
    }

    private static func traditionalTitle(for id: VoiceControlAttributeID) -> String {
        switch id {
        case .roleName: "角色姓名"
        case .language: "語言"
        case .dialect: "方言"
        case .age: "年齡"
        case .genderPresentation: "聲線"
        case .pitch: "音高"
        case .speed: "語速"
        case .volume: "音量"
        case .clarity: "清晰度"
        case .fluency: "流暢度"
        case .accent: "口音細節"
        case .emotion: "情緒"
        case .tone: "語調"
        case .persona: "角色 / persona"
        case .acousticTexture: "音色質感"
        case .humanLikeness: "擬人感"
        case .background: "背景資訊"
        case .gradient: "漸變控制"
        case .negativePrompt: "約束"
        case .customPrompt: "補充指令"
        }
    }

    private static func englishCandidates(for id: VoiceControlAttributeID) -> [String] {
        switch id {
        case .roleName:
            return [
                "Narrator", "Documentary narrator", "News anchor", "Late-night radio host", "Science explainer",
                "Senior scientist", "Young reporter", "Calm captain", "Warm teacher", "Mature mentor",
                "Curious teen", "Nervous student", "Business presenter", "Court witness", "Medical consultant",
                "Shopping host", "Low bar storyteller", "Ironic villain", "Adventurous child", "Friendly storyteller"
            ]
        case .language:
            return [
                "Chinese", "English", "Japanese", "Korean", "German", "French", "Russian", "Portuguese", "Spanish", "Italian",
                "Mandarin Chinese", "American English", "British English", "Canadian English", "Australian English",
                "European Portuguese", "Brazilian Portuguese", "Latin American Spanish", "Castilian Spanish", "International English"
            ]
        case .dialect:
            return [
                "Mandarin", "Beijing dialect", "Sichuan dialect", "Natural Mandarin", "Standard Mandarin",
                "Light northern accent", "Light southern accent", "Broadcast Mandarin", "Conversational Mandarin", "Casual Mandarin",
                "American English accent", "British English accent", "Australian English accent", "Tokyo Japanese accent", "Kansai-leaning accent",
                "Seoul Korean accent", "Standard German accent", "Standard French accent", "Standard Russian accent", "Standard Spanish accent"
            ]
        case .age:
            return [
                "Child", "around 8 years old", "Teenager", "around 17 years old", "around 20 years old",
                "around 25 years old", "around 30 years old", "around 35 years old", "around 40 years old", "around 45 years old",
                "Middle-aged", "around 50 years old", "around 55 years old", "around 60 years old", "nearly seventy",
                "Elderly", "young adult", "mature adult", "youthful presence", "elder presence"
            ]
        case .genderPresentation:
            return [
                "Female voice", "Male voice", "Androgynous voice", "young clear voice", "mature magnetic female voice",
                "deep male voice", "bright boyish voice", "childlike voice", "female announcer voice", "male announcer voice",
                "gentle female voice", "steady male voice", "fresh young male voice", "bright young female voice", "husky male voice",
                "breathy female voice", "heavy bass male voice", "light young girl voice", "mature mentor voice", "calm commander voice"
            ]
        case .pitch:
            return [
                "low and steady", "low pitch", "medium-low pitch", "medium pitch", "medium-high pitch",
                "high pitch", "slightly higher pitch", "slightly lower pitch", "large pitch movement", "small pitch movement",
                "slight rise at sentence endings", "natural fall at sentence endings", "raise pitch on keywords", "mostly steady contour", "pitch rises under tension",
                "lower pitch when restrained", "more bright high frequencies", "stronger low-frequency body", "natural high-low transitions", "avoid sharp high notes"
            ]
        case .speed:
            return [
                "natural pace", "moderate pace", "slightly slow pace", "slightly fast pace", "slow and clear",
                "fast but clear", "start slowly then gradually speed up", "start naturally and slow down at the end", "longer pauses between sentences", "tight rhythm for short lines",
                "stable long sentences", "slow down for technical terms", "slightly faster with stronger emotion", "accelerate during tense moments", "slow down for memories",
                "news-reading rhythm", "casual chat rhythm", "steady audiobook rhythm", "trailer-style momentum", "avoid dragging"
            ]
        case .volume:
            return [
                "medium volume", "stable volume", "slightly low volume", "slightly high volume", "loud and forceful",
                "close low voice", "start low and grow stronger", "slightly emphasize key words", "avoid sudden loudness", "slightly stronger in emotional passages",
                "lower volume for intimate scenes", "raise volume for speeches", "balanced broadcast volume", "whisper but keep clear", "distant narrative feel",
                "close conversational feel", "lower volume at the ending", "increase volume on turns", "avoid clipping", "avoid sounding too weak"
            ]
        case .clarity:
            return [
                "clear articulation", "very clear articulation", "slow down and clarify key words", "clear numbers", "clear English words",
                "clear proper nouns", "slow down formulas and symbols", "slightly conversational but not blurry", "clear pauses around complex punctuation", "clean sentence onsets",
                "do not swallow endings", "avoid heavy linking", "preserve natural diction", "broadcast-level clarity", "characterful but clear",
                "stay clear even when quiet", "stay clear at fast pace", "clear multilingual words", "do not blur under emotion", "avoid mechanical syllable chopping"
            ]
        case .fluency:
            return [
                "fluent delivery", "coherent delivery", "natural pauses between sentences", "preserve key pauses", "one continuous flow",
                "smooth paragraph transitions", "natural dialogue response", "stable narration rhythm", "long sentences do not break", "short lines have breath",
                "slight hesitation", "natural breathing", "avoid repeated stutters", "avoid mechanical pauses", "pause before key plot points",
                "leave space after rhetorical questions", "small pause at turns", "natural emotion transitions", "clear semantic boundaries", "finish the full sentence before closing"
            ]
        case .accent:
            return [
                "standard clear pronunciation", "natural conversational pronunciation", "news anchor style", "casual spoken style", "announcer style",
                "radio host style", "documentary narration style", "classroom explainer style", "friendly chat style", "formal report style",
                "stage storytelling style", "film narration style", "calm low delivery", "bright clean delivery", "soft intimate delivery",
                "restrained objective delivery", "lowered suspense delivery", "comforting delivery", "urgent bulletin delivery", "audiobook reading style"
            ]
        case .emotion:
            return [
                "calm and trustworthy", "gentle, clear, natural", "serious and firm", "tense but restrained", "close and natural",
                "slight smile", "restrained sadness", "suppressed anger", "bright excitement", "light curiosity",
                "from suppressed to explosive", "cool observer", "subtle irony", "anxious unease", "warm nostalgia",
                "solemn dignity", "restrained intimacy", "steady reassurance", "authoritative certainty", "suspenseful tension"
            ]
        case .tone:
            return [
                "objective and steady", "warm narrative", "authoritative restraint", "natural conversational", "news broadcast",
                "documentary narration", "late-night radio", "subtle irony", "close low voice", "bright and crisp",
                "solemn and slow", "urgent momentum", "natural rise on questions", "falling conclusion lines", "stronger turn lines",
                "gradually stronger emotion", "comforting intonation", "commanding intonation", "lowered suspense", "trailer-style silence"
            ]
        case .persona:
            return [
                "senior strategic scientist", "calm documentary narrator", "field news reporter", "warm science teacher", "late-night radio host",
                "mature therapist", "young office worker", "nervous student", "space captain", "business presenter",
                "court witness", "medical consultant", "shopping host", "friendly storyteller", "calm antagonist",
                "adventurous child", "history narrator", "product manager", "engineering explainer", "story narrator"
            ]
        case .acousticTexture:
            return [
                "warm and steady", "deep and full", "clear and clean", "slightly breathy", "slightly husky",
                "magnetic and soft", "bright with subtle grain", "heavy low end", "clean without reverb", "close to the ear",
                "wide narrative space", "broadcast texture", "radio texture", "natural human feel", "fresh youthful feel",
                "mature stable feel", "sad husky feel", "sweet light feel", "cool technological feel", "avoid metallic texture"
            ]
        case .humanLikeness:
            return [
                "keep natural breathing and slight pauses", "add brief hesitation", "slight smile in the voice", "natural inhale before sentences", "speak like face-to-face conversation",
                "leave space before key lines", "emotion changes with breath", "quiet voice still sounds natural", "avoid machine broadcast tone", "preserve spoken rhythm",
                "do not over-smooth", "slight stumble without hurting clarity", "natural reaction speed", "questions sound like real questions", "exclamations are not overacted",
                "natural closing at the end", "human spacing between paragraphs", "preserve presence", "like real narration", "avoid synthetic tone"
            ]
        case .background:
            return [
                "quiet recording studio", "late-night radio booth", "low-frequency ambience on a spaceship bridge", "press conference scene", "dim bar corner",
                "university classroom", "hospital consultation room", "court testimony room", "documentary outdoor narration", "office meeting room",
                "rainy night inside a car", "city street in the morning", "old laboratory", "children's animation scene", "business roadshow stage",
                "historical archive", "science-fiction control room", "therapy room", "product launch", "late-night monologue space"
            ]
        case .gradient:
            return [
                "start steady, grow stronger in the middle, close softly", "start slowly then gradually accelerate", "emotion moves from restrained to firm", "volume rises from low to medium-high", "tension gradually increases",
                "from relaxed to serious", "from doubt to confirmation", "from calm to slightly excited", "leave a short pause at the end", "suddenly slow down before key lines",
                "first sentence low, then return to natural", "add pressure in the middle", "lower tone at the end", "pace gets faster after the turn", "slow down explanatory parts",
                "increase volume in climactic passages", "dialogue reactions become more natural", "from observer to involved", "from smiling to restrained", "avoid overacting at the start"
            ]
        case .negativePrompt:
            return [
                "avoid cartoonish delivery", "avoid overacting", "avoid mechanical broadcast", "do not change the current speaker's core timbre", "avoid sharp high notes",
                "do not swallow words", "do not drag", "avoid sudden clipping", "avoid excessive crying tone", "avoid excessive cuteness",
                "do not read role names aloud", "do not read stage directions aloud", "do not add laughter not present in the text", "avoid strong background noise", "do not damage Mandarin clarity",
                "avoid advertisement tone", "avoid exaggerated dialect", "do not go so low that it becomes unclear", "do not change text meaning", "do not omit keywords"
            ]
        case .customPrompt:
            return [
                "slow down and clarify key terms", "close each paragraph naturally", "keep long passages stable", "slightly separate dialogue from narration", "read numbers and English words clearly",
                "lower tone slightly on ironic lines", "leave space after suspense lines", "be more patient with technical terms", "do not clip on high-energy lines", "preserve natural spoken feeling",
                "do not read parenthetical notes aloud", "pause according to sentence meaning", "switch naturally in mixed-language text", "fit short-video narration", "fit long-form audiobooks",
                "fit science explanation", "fit multi-role short drama", "fit product demos", "fit formal reporting", "fit immersive storytelling"
            ]
        }
    }

    private static func neutralAccentCandidates(language: AppLanguage) -> [String] {
        switch AppLanguage.resolved(language) {
        case .simplifiedChinese:
            return candidates(for: .accent, workflow: .voiceDesign)
        case .traditionalChinese:
            return candidates(for: .accent, workflow: .voiceDesign).map(traditionalizedCandidate)
        default:
            return englishCandidates(for: .accent)
        }
    }

    private static func traditionalizedCandidate(_ value: String) -> String {
        var result = value
        let replacements: [(String, String)] = [
            ("语", "語"), ("声", "聲"), ("气", "氣"), ("线", "線"), ("质", "質"), ("稳", "穩"),
            ("轻", "輕"), ("讲", "講"), ("学", "學"), ("录", "錄"), ("频", "頻"), ("频", "頻"),
            ("响", "響"), ("标", "標"), ("准", "準"), ("间", "間"), ("渐", "漸"), ("变", "變"),
            ("绪", "緒"), ("张", "張"), ("觉", "覺"), ("乐", "樂"), ("儿", "兒"), ("对", "對"),
            ("话", "話"), ("国", "國"), ("节", "節"), ("开", "開"), ("关", "關"), ("后", "後"),
            ("时", "時"), ("复", "複"), ("号", "號"), ("词", "詞"), ("术", "術"), ("专", "專"),
            ("态", "態"), ("数", "數"), ("为", "為"), ("这", "這"), ("个", "個"), ("现", "現"),
            ("发", "發"), ("觉", "覺"), ("温", "溫"), ("师", "師"), ("历", "歷"), ("导", "導"),
            ("员", "員"), ("讯", "訊"), ("场", "場"), ("写", "寫"), ("广", "廣"), ("级", "級")
        ]
        for (source, target) in replacements {
            result = result.replacingOccurrences(of: source, with: target)
        }
        return result
    }
}

public extension VoiceControlProfile {
    static func defaultNarration(language: AppLanguage) -> VoiceControlProfile {
        switch AppLanguage.resolved(language) {
        case .simplifiedChinese:
            return .defaultNarration
        case .traditionalChinese:
            return VoiceControlProfile(
                roleName: "旁白",
                language: "中文",
                dialect: "普通話",
                speed: "語速自然",
                volume: "音量中等",
                clarity: "吐字清楚",
                fluency: "停頓自然，表達連貫",
                emotion: "溫柔、清晰、自然",
                acousticTexture: "溫暖、穩定、適合旁白"
            )
        default:
            return VoiceControlProfile(
                roleName: "Narrator",
                language: "English",
                dialect: "",
                speed: "natural pace",
                volume: "medium volume",
                clarity: "clear articulation",
                fluency: "natural pauses and coherent delivery",
                emotion: "gentle, clear, natural",
                acousticTexture: "warm, steady, suited for narration"
            )
        }
    }

    static func isLocalizedDefaultNarration(_ profile: VoiceControlProfile) -> Bool {
        let trimmed = profile.trimmed
        return AppLanguage.interfaceLanguages.contains { trimmed == defaultNarration(language: $0).trimmed }
    }
}

public extension VoiceControlPreset {
    func title(language: AppLanguage) -> String {
        switch AppLanguage.resolved(language) {
        case .english:
            switch id {
            case "official-acoustic-announcer": "Acoustic"
            case "official-age-childlike": "Age Identity"
            case "official-emotion-acting": "Emotion Acting"
            case "official-gradient-outburst": "Gradient"
            case "official-persona-scientist": "Persona"
            case "official-human-chat": "Human"
            case "customvoice-warm-narration": "Warm Narration"
            case "customvoice-clear-science": "Clear Science"
            case "customvoice-suspense": "Suspense"
            case "voice-design-calm-female": "Calm Female"
            case "voice-design-elder-scientist": "Elder Scientist"
            case "voice-design-radio-night": "Night Radio"
            default: category.title(language: language)
            }
        case .traditionalChinese:
            switch id {
            case "official-acoustic-announcer": "聲學屬性"
            case "official-age-childlike": "年齡身分"
            case "official-emotion-acting": "情緒表演"
            case "official-gradient-outburst": "漸變控制"
            case "official-persona-scientist": "角色背景"
            case "official-human-chat": "擬人閒聊"
            case "customvoice-warm-narration": "溫暖旁白"
            case "customvoice-clear-science": "清晰科普"
            case "customvoice-suspense": "懸疑推進"
            case "voice-design-calm-female": "沉穩女聲"
            case "voice-design-elder-scientist": "老年科學家"
            case "voice-design-radio-night": "夜間電台"
            default: title
            }
        case .simplifiedChinese:
            title
        default:
            title(language: .english)
        }
    }
}
