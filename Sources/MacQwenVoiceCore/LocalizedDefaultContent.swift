import Foundation

public struct LocalizedDefaultContent: Equatable, Sendable {
    public var projectTitle: String
    public var scriptText: String
    public var builtinControlInstruction: String
    public var voiceDesignControlInstruction: String
    public var voiceDesignSynthesisText: String
    public var voiceDesignLanguage: String
    public var cloneReferenceTranscript: String
    public var cloneReferenceExamples: [CloneReferenceTranscriptExampleGroup]
    public var clonePurpose: String
    public var cloneVoiceName: String
    public var scriptRewriteStylePrompt: String
    public var voiceToolsStatusMessage: String
    public var voiceToolsOutputName: String

    public static func defaults(for language: AppLanguage) -> LocalizedDefaultContent {
        switch AppLanguage.resolved(language) {
        case .system:
            return defaults(for: .english)
        case .english:
            return .init(
                projectTitle: "New Narration Project",
                scriptText: "My observation is that I often notice small changes in other people's emotions.",
                builtinControlInstruction: "warm and bright, naturally resonant, clear articulation, moderate pace, friendly and engaging delivery.",
                voiceDesignControlInstruction: "warm and bright, naturally resonant, clear articulation, moderate pace, friendly and engaging delivery.",
                voiceDesignSynthesisText: "Today we are going to explain a complex but genuinely interesting technical question.",
                voiceDesignLanguage: "English",
                cloneReferenceTranscript: "The evening slowly settles in, the wind outside is light, and I read this sentence in a steady, clear voice.",
                cloneReferenceExamples: [
                    .init(language: "English", examples: [
                        "The evening slowly settles in, the wind outside is light, and I read this sentence in a steady, clear voice.",
                        "The air feels quiet today, as if every hurried thing has gently slowed down.",
                        "I want to say this sentence a little more softly, and also a little more clearly.",
                        "Lights come on in the distance, and the sound of the city slowly becomes gentle.",
                        "If you are listening to this voice, I hope it feels real, natural, and a little warm.",
                        "Let us begin slowly, without rushing, and finish the sentence in front of us."
                    ])
                ],
                clonePurpose: "My own voice or an authorized voice, used for local narration generation",
                cloneVoiceName: "My Cloned Voice",
                scriptRewriteStylePrompt: "science fiction, restrained, immersive",
                voiceToolsStatusMessage: "Select two or more audio files to merge them in order",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .simplifiedChinese:
            return .init(
                projectTitle: "新旁白项目",
                scriptText: "其实我真的有发现，我是一个特别善于观察别人情绪的人。",
                builtinControlInstruction: VoiceStudioDefaults.defaultBuiltinControlInstruction,
                voiceDesignControlInstruction: VoiceStudioDefaults.defaultVoiceDesignControlInstruction,
                voiceDesignSynthesisText: "今天我们来讲一个复杂但非常有意思的技术问题。",
                voiceDesignLanguage: "Chinese",
                cloneReferenceTranscript: VoiceStudioDefaults.cloneReferenceTranscript,
                cloneReferenceExamples: VoiceStudioDefaults.cloneReferenceTranscriptExamples,
                clonePurpose: "本人声音或已获授权，用于本地旁白生成",
                cloneVoiceName: "我的克隆音色",
                scriptRewriteStylePrompt: "科幻、克制、沉浸式",
                voiceToolsStatusMessage: "选择两个或更多音频后即可按顺序合并",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .traditionalChinese:
            return .init(
                projectTitle: "新旁白專案",
                scriptText: "其實我真的有發現，我是一個特別善於觀察別人情緒的人。",
                builtinControlInstruction: "陽光溫暖，聲音自然洪亮，吐字清晰，語速適中，表達親切且有感染力。",
                voiceDesignControlInstruction: "陽光溫暖，聲音自然洪亮，吐字清晰，語速適中，表達親切且有感染力。",
                voiceDesignSynthesisText: "今天我們來講一個複雜但非常有意思的技術問題。",
                voiceDesignLanguage: "Chinese",
                cloneReferenceTranscript: "夜色慢慢落下來，窗外的風很輕，我用平穩而清晰的聲音讀完這一段話。",
                cloneReferenceExamples: [
                    .init(language: "繁體中文", examples: [
                        "夜色慢慢落下來，窗外的風很輕，我用平穩而清晰的聲音讀完這一段話。",
                        "今天的空氣很安靜，像是把所有匆忙都輕輕放慢了一點。",
                        "我想把這句話說得溫柔一些，也說得清楚一些，讓你能聽見每一個停頓。",
                        "遠處的燈一點點亮起來，城市的聲音也慢慢變得柔和。",
                        "如果你正在聽這段聲音，希望它聽起來真實、自然，也帶著一點溫暖。",
                        "我們先慢慢開始，不急著抵達，只把眼前這一句話認真說完。"
                    ])
                ],
                clonePurpose: "本人聲音或已獲授權，用於本機旁白製作",
                cloneVoiceName: "我的克隆音色",
                scriptRewriteStylePrompt: "科幻、克制、沉浸式",
                voiceToolsStatusMessage: "選擇兩個或更多聲音檔後即可依序合併",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .japanese:
            return .init(
                projectTitle: "新しいナレーションプロジェクト",
                scriptText: "私は、人の感情の小さな変化に気づくのが得意だと本当に感じています。",
                builtinControlInstruction: "明るく温かく、自然に響く声。発音は明瞭、速度は中程度で、親しみやすく説得力のある話し方。",
                voiceDesignControlInstruction: "明るく温かく、自然に響く声。発音は明瞭、速度は中程度で、親しみやすく説得力のある話し方。",
                voiceDesignSynthesisText: "今日は、複雑ですがとても興味深い技術的な問題について説明します。",
                voiceDesignLanguage: "Japanese",
                cloneReferenceTranscript: "夜がゆっくりと降りてきて、窓の外の風は静かで、私はこの一文を落ち着いた明瞭な声で読みます。",
                cloneReferenceExamples: [
                    .init(language: "日本語", examples: [
                        "夜がゆっくりと降りてきて、窓の外の風は静かで、私はこの一文を落ち着いた明瞭な声で読みます。",
                        "今日の空気は静かで、急いでいたものが少しだけゆっくりになったようです。",
                        "この言葉を少しやさしく、そしてはっきりと届けたいと思います。",
                        "遠くの灯りが少しずつともり、街の音もゆっくり穏やかになります。",
                        "この声が自然で、聞き取りやすく、少し温かく感じられますように。",
                        "急がずに始めて、目の前の一文を丁寧に読み終えます。"
                    ])
                ],
                clonePurpose: "本人の声、または許可された声をローカルのナレーション生成に使用",
                cloneVoiceName: "私のクローン音声",
                scriptRewriteStylePrompt: "SF、抑制された、没入感のある",
                voiceToolsStatusMessage: "2つ以上の音声ファイルを選ぶと順番に結合できます",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .korean:
            return .init(
                projectTitle: "새 내레이션 프로젝트",
                scriptText: "나는 다른 사람의 감정 변화를 꽤 잘 알아차리는 사람이라고 느낍니다.",
                builtinControlInstruction: "밝고 따뜻하며 자연스럽게 울리는 목소리, 또렷한 발음, 적당한 속도, 친근하고 설득력 있는 전달.",
                voiceDesignControlInstruction: "밝고 따뜻하며 자연스럽게 울리는 목소리, 또렷한 발음, 적당한 속도, 친근하고 설득력 있는 전달.",
                voiceDesignSynthesisText: "오늘은 복잡하지만 정말 흥미로운 기술 문제를 설명해 보겠습니다.",
                voiceDesignLanguage: "Korean",
                cloneReferenceTranscript: "밤이 천천히 내려앉고 창밖의 바람은 가볍습니다. 나는 이 문장을 차분하고 또렷한 목소리로 읽습니다.",
                cloneReferenceExamples: [
                    .init(language: "한국어", examples: [
                        "밤이 천천히 내려앉고 창밖의 바람은 가볍습니다. 나는 이 문장을 차분하고 또렷한 목소리로 읽습니다.",
                        "오늘의 공기는 조용해서 모든 급한 것들이 조금 느려진 듯합니다.",
                        "이 문장을 조금 더 부드럽게, 그리고 조금 더 분명하게 말하고 싶습니다.",
                        "멀리 불빛이 하나씩 켜지고 도시의 소리도 천천히 부드러워집니다.",
                        "이 목소리가 자연스럽고 듣기 편하며 약간 따뜻하게 느껴지길 바랍니다.",
                        "서두르지 않고 천천히 시작해서 눈앞의 한 문장을 끝까지 읽겠습니다."
                    ])
                ],
                clonePurpose: "본인 목소리 또는 허가받은 목소리를 로컬 내레이션 생성에 사용",
                cloneVoiceName: "내 복제 음성",
                scriptRewriteStylePrompt: "SF, 절제된, 몰입감 있는",
                voiceToolsStatusMessage: "두 개 이상의 오디오 파일을 선택하면 순서대로 병합할 수 있습니다",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .german:
            return .init(
                projectTitle: "Neues Erzahlprojekt",
                scriptText: "Mir ist wirklich aufgefallen, dass ich feine Stimmungswechsel bei anderen Menschen gut wahrnehme.",
                builtinControlInstruction: "Warm und hell, naturlich resonant, klare Artikulation, mittleres Tempo, freundlich und mitreißend vorgetragen.",
                voiceDesignControlInstruction: "Warm und hell, naturlich resonant, klare Artikulation, mittleres Tempo, freundlich und mitreißend vorgetragen.",
                voiceDesignSynthesisText: "Heute erklaren wir eine komplexe, aber wirklich interessante technische Frage.",
                voiceDesignLanguage: "German",
                cloneReferenceTranscript: "Der Abend senkt sich langsam, der Wind vor dem Fenster ist leise, und ich lese diesen Satz mit ruhiger, klarer Stimme.",
                cloneReferenceExamples: [
                    .init(language: "Deutsch", examples: [
                        "Der Abend senkt sich langsam, der Wind vor dem Fenster ist leise, und ich lese diesen Satz mit ruhiger, klarer Stimme.",
                        "Die Luft ist heute still, als ware alles Eilige sanft verlangsamt worden.",
                        "Ich mochte diesen Satz etwas sanfter und zugleich deutlicher aussprechen.",
                        "In der Ferne gehen die Lichter an, und die Stadt klingt langsam ruhiger.",
                        "Diese Stimme soll naturlich, klar und ein wenig warm klingen.",
                        "Wir beginnen langsam und lesen diesen einen Satz aufmerksam zu Ende."
                    ])
                ],
                clonePurpose: "Eigene oder autorisierte Stimme fur lokale Erzahlungserzeugung",
                cloneVoiceName: "Meine geklonte Stimme",
                scriptRewriteStylePrompt: "Science-Fiction, zuruckhaltend, immersiv",
                voiceToolsStatusMessage: "Wahlen Sie zwei oder mehr Audiodateien, um sie der Reihe nach zusammenzufuhren",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .french:
            return .init(
                projectTitle: "Nouveau projet de narration",
                scriptText: "J'ai vraiment remarque que je percois tres bien les changements subtils d'emotion chez les autres.",
                builtinControlInstruction: "Chaleureux et lumineux, resonance naturelle, articulation claire, rythme modere, ton proche et captivant.",
                voiceDesignControlInstruction: "Chaleureux et lumineux, resonance naturelle, articulation claire, rythme modere, ton proche et captivant.",
                voiceDesignSynthesisText: "Aujourd'hui, nous allons expliquer une question technique complexe mais vraiment interessante.",
                voiceDesignLanguage: "French",
                cloneReferenceTranscript: "Le soir descend lentement, le vent dehors est leger, et je lis cette phrase d'une voix calme et claire.",
                cloneReferenceExamples: [
                    .init(language: "Français", examples: [
                        "Le soir descend lentement, le vent dehors est leger, et je lis cette phrase d'une voix calme et claire.",
                        "L'air d'aujourd'hui est calme, comme si toute urgence avait doucement ralenti.",
                        "Je veux dire cette phrase avec un peu plus de douceur et de clarte.",
                        "Au loin, les lumieres s'allument peu a peu, et la ville devient plus douce.",
                        "J'espere que cette voix paraitra naturelle, claire et legerement chaleureuse.",
                        "Commencons lentement, sans nous presser, et terminons cette phrase avec soin."
                    ])
                ],
                clonePurpose: "Voix personnelle ou autorisee pour la narration locale",
                cloneVoiceName: "Ma voix clonee",
                scriptRewriteStylePrompt: "science-fiction, retenu, immersif",
                voiceToolsStatusMessage: "Selectionnez au moins deux fichiers audio pour les fusionner dans l'ordre",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .russian:
            return .init(
                projectTitle: "Новый проект озвучивания",
                scriptText: "Я действительно замечаю, что хорошо улавливаю тонкие изменения эмоций у других людей.",
                builtinControlInstruction: "Теплый и светлый голос, естественный резонанс, четкая дикция, умеренный темп, дружелюбная и выразительная подача.",
                voiceDesignControlInstruction: "Теплый и светлый голос, естественный резонанс, четкая дикция, умеренный темп, дружелюбная и выразительная подача.",
                voiceDesignSynthesisText: "Сегодня мы объясним сложный, но по-настоящему интересный технический вопрос.",
                voiceDesignLanguage: "Russian",
                cloneReferenceTranscript: "Вечер медленно опускается, ветер за окном легкий, и я читаю это предложение спокойным и ясным голосом.",
                cloneReferenceExamples: [
                    .init(language: "Русский", examples: [
                        "Вечер медленно опускается, ветер за окном легкий, и я читаю это предложение спокойным и ясным голосом.",
                        "Сегодня воздух тихий, словно все спешное немного замедлилось.",
                        "Я хочу произнести эту фразу мягче и яснее.",
                        "Вдали постепенно загораются огни, и город звучит мягче.",
                        "Пусть этот голос звучит естественно, понятно и немного тепло.",
                        "Начнем спокойно, без спешки, и внимательно дочитаем эту фразу."
                    ])
                ],
                clonePurpose: "Собственный или разрешенный голос для локальной генерации озвучивания",
                cloneVoiceName: "Мой клонированный голос",
                scriptRewriteStylePrompt: "научная фантастика, сдержанно, с погружением",
                voiceToolsStatusMessage: "Выберите два или более аудиофайла, чтобы объединить их по порядку",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .portuguese:
            return .init(
                projectTitle: "Novo projeto de narração",
                scriptText: "Eu realmente percebo que sou bom em notar pequenas mudanças nas emoções das pessoas.",
                builtinControlInstruction: "Quente e luminoso, ressonância natural, articulação clara, ritmo moderado, entrega próxima e envolvente.",
                voiceDesignControlInstruction: "Quente e luminoso, ressonância natural, articulação clara, ritmo moderado, entrega próxima e envolvente.",
                voiceDesignSynthesisText: "Hoje vamos explicar uma questão técnica complexa, mas realmente interessante.",
                voiceDesignLanguage: "Portuguese",
                cloneReferenceTranscript: "A noite desce devagar, o vento lá fora é leve, e eu leio esta frase com uma voz calma e clara.",
                cloneReferenceExamples: [
                    .init(language: "Português", examples: [
                        "A noite desce devagar, o vento lá fora é leve, e eu leio esta frase com uma voz calma e clara.",
                        "O ar de hoje está quieto, como se toda pressa tivesse desacelerado um pouco.",
                        "Quero dizer esta frase com mais suavidade e também com mais clareza.",
                        "As luzes ao longe se acendem aos poucos, e a cidade soa mais suave.",
                        "Espero que esta voz pareça natural, clara e um pouco acolhedora.",
                        "Vamos começar devagar, sem pressa, e terminar esta frase com atenção."
                    ])
                ],
                clonePurpose: "Minha voz ou uma voz autorizada, usada para narração local",
                cloneVoiceName: "Minha voz clonada",
                scriptRewriteStylePrompt: "ficção científica, contido, imersivo",
                voiceToolsStatusMessage: "Selecione dois ou mais arquivos de áudio para mesclar em ordem",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .spanish:
            return .init(
                projectTitle: "Nuevo proyecto de narración",
                scriptText: "De verdad he notado que se me da bien percibir pequeños cambios en las emociones de otras personas.",
                builtinControlInstruction: "Cálido y luminoso, resonancia natural, articulación clara, ritmo moderado, entrega cercana y atractiva.",
                voiceDesignControlInstruction: "Cálido y luminoso, resonancia natural, articulación clara, ritmo moderado, entrega cercana y atractiva.",
                voiceDesignSynthesisText: "Hoy vamos a explicar una cuestión técnica compleja, pero realmente interesante.",
                voiceDesignLanguage: "Spanish",
                cloneReferenceTranscript: "La noche cae despacio, el viento afuera es ligero, y leo esta frase con una voz serena y clara.",
                cloneReferenceExamples: [
                    .init(language: "Español", examples: [
                        "La noche cae despacio, el viento afuera es ligero, y leo esta frase con una voz serena y clara.",
                        "El aire de hoy está tranquilo, como si todo lo urgente se hubiera detenido un poco.",
                        "Quiero decir esta frase con un poco más de suavidad y también con más claridad.",
                        "A lo lejos se encienden las luces, y la ciudad empieza a sonar más suave.",
                        "Espero que esta voz suene natural, clara y un poco cálida.",
                        "Empecemos despacio, sin prisa, y terminemos esta frase con cuidado."
                    ])
                ],
                clonePurpose: "Mi voz o una voz autorizada, usada para narración local",
                cloneVoiceName: "Mi voz clonada",
                scriptRewriteStylePrompt: "ciencia ficción, contenido, inmersivo",
                voiceToolsStatusMessage: "Seleccione dos o más archivos de audio para fusionarlos en orden",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        case .italian:
            return .init(
                projectTitle: "Nuovo progetto di narrazione",
                scriptText: "Mi sono davvero accorto di saper cogliere piccoli cambiamenti nelle emozioni degli altri.",
                builtinControlInstruction: "Caldo e luminoso, risonanza naturale, articolazione chiara, ritmo moderato, tono vicino e coinvolgente.",
                voiceDesignControlInstruction: "Caldo e luminoso, risonanza naturale, articolazione chiara, ritmo moderato, tono vicino e coinvolgente.",
                voiceDesignSynthesisText: "Oggi spiegheremo una questione tecnica complessa, ma davvero interessante.",
                voiceDesignLanguage: "Italian",
                cloneReferenceTranscript: "La sera scende lentamente, il vento fuori è leggero, e leggo questa frase con una voce calma e chiara.",
                cloneReferenceExamples: [
                    .init(language: "Italiano", examples: [
                        "La sera scende lentamente, il vento fuori è leggero, e leggo questa frase con una voce calma e chiara.",
                        "L'aria di oggi è tranquilla, come se ogni fretta fosse stata rallentata.",
                        "Voglio dire questa frase con un po' più di dolcezza e anche con più chiarezza.",
                        "Le luci in lontananza si accendono lentamente, e la città diventa più morbida.",
                        "Spero che questa voce sembri naturale, chiara e leggermente calda.",
                        "Cominciamo piano, senza fretta, e leggiamo con cura questa frase."
                    ])
                ],
                clonePurpose: "La mia voce o una voce autorizzata, usata per narrazione locale",
                cloneVoiceName: "La mia voce clonata",
                scriptRewriteStylePrompt: "fantascienza, controllato, immersivo",
                voiceToolsStatusMessage: "Seleziona due o più file audio per unirli in ordine",
                voiceToolsOutputName: "voice-tools-merged.webm"
            )
        }
    }

    public static func allDefaults(for keyPath: KeyPath<LocalizedDefaultContent, String>) -> Set<String> {
        Set(AppLanguage.interfaceLanguages.map { defaults(for: $0)[keyPath: keyPath].normalizedDefaultValue })
    }

    public static func isDefault(_ value: String, for keyPath: KeyPath<LocalizedDefaultContent, String>) -> Bool {
        allDefaults(for: keyPath).contains(value.normalizedDefaultValue)
    }

    public static func replacingDefault(
        _ value: String,
        with keyPath: KeyPath<LocalizedDefaultContent, String>,
        language: AppLanguage
    ) -> String {
        isDefault(value, for: keyPath) ? defaults(for: language)[keyPath: keyPath] : value
    }
}

private extension String {
    var normalizedDefaultValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
