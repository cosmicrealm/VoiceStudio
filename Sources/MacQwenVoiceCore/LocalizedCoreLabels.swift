import Foundation

public extension ScriptStudioWorkflow {
    func title(language: AppLanguage) -> String {
        switch AppLanguage.resolved(language) {
        case .english:
            switch self {
            case .builtin: "Premium Generation"
            case .custom: "Clone Generation"
            case .voiceDesign: "Voice Creation"
            case .multiRole: "Dialogue Generation"
            }
        case .simplifiedChinese:
            title
        case .traditionalChinese:
            switch self {
            case .builtin: "精品生成"
            case .custom: "克隆生成"
            case .voiceDesign: "創造生成"
            case .multiRole: "對話生成"
            }
        case .japanese:
            switch self {
            case .builtin: "プレミアム生成"
            case .custom: "クローン生成"
            case .voiceDesign: "音色作成"
            case .multiRole: "会話生成"
            }
        case .korean:
            switch self {
            case .builtin: "프리미엄 생성"
            case .custom: "복제 생성"
            case .voiceDesign: "음성 생성"
            case .multiRole: "대화 생성"
            }
        case .german:
            switch self {
            case .builtin: "Premium-Erzeugung"
            case .custom: "Klon-Erzeugung"
            case .voiceDesign: "Stimme erstellen"
            case .multiRole: "Dialog-Erzeugung"
            }
        case .french:
            switch self {
            case .builtin: "Génération premium"
            case .custom: "Génération clone"
            case .voiceDesign: "Création de voix"
            case .multiRole: "Génération de dialogue"
            }
        case .russian:
            switch self {
            case .builtin: "Премиум генерация"
            case .custom: "Генерация клона"
            case .voiceDesign: "Создание голоса"
            case .multiRole: "Генерация диалога"
            }
        case .portuguese:
            switch self {
            case .builtin: "Geração premium"
            case .custom: "Geração clonada"
            case .voiceDesign: "Criação de voz"
            case .multiRole: "Geração de diálogo"
            }
        case .spanish:
            switch self {
            case .builtin: "Generación premium"
            case .custom: "Generación clonada"
            case .voiceDesign: "Creación de voz"
            case .multiRole: "Generación de diálogo"
            }
        case .italian:
            switch self {
            case .builtin: "Generazione premium"
            case .custom: "Generazione clone"
            case .voiceDesign: "Creazione voce"
            case .multiRole: "Generazione dialogo"
            }
        case .system:
            title(language: .english)
        }
    }
}

public extension ScriptStudioDetectedLanguage {
    func displayTitle(language: AppLanguage) -> String {
        switch AppLanguage.resolved(language) {
        case .english:
            switch self {
            case .chinese: "Chinese"
            case .english: "English"
            case .japanese: "Japanese"
            case .korean: "Korean"
            case .russian: "Russian"
            case .mixed: "Mixed"
            case .unknown: "Unknown"
            }
        case .traditionalChinese:
            switch self {
            case .chinese: "中文"
            case .english: "英文"
            case .japanese: "日文"
            case .korean: "韓文"
            case .russian: "俄文"
            case .mixed: "混合"
            case .unknown: "未知"
            }
        case .simplifiedChinese:
            displayTitle
        default:
            displayTitle(language: .english)
        }
    }
}

public extension ScriptStudioLanguageOption {
    func displayTitle(language: AppLanguage) -> String {
        switch AppLanguage.resolved(language) {
        case .english:
            switch self {
            case .automatic: "Auto"
            case .chinese: "Chinese"
            case .beijingDialect: "Beijing dialect"
            case .sichuanDialect: "Sichuan dialect"
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
        case .traditionalChinese:
            switch self {
            case .automatic: "自動"
            case .chinese: "中文"
            case .beijingDialect: "北京話"
            case .sichuanDialect: "四川話"
            case .english: "英文"
            case .japanese: "日文"
            case .korean: "韓文"
            case .german: "德文"
            case .french: "法文"
            case .russian: "俄文"
            case .portuguese: "葡萄牙文"
            case .spanish: "西班牙文"
            case .italian: "義大利文"
            }
        case .simplifiedChinese:
            displayTitle
        case .japanese:
            switch self {
            case .automatic: "自動"
            case .chinese: "中国語"
            case .beijingDialect: "北京方言"
            case .sichuanDialect: "四川方言"
            case .english: "英語"
            case .japanese: "日本語"
            case .korean: "韓国語"
            case .german: "ドイツ語"
            case .french: "フランス語"
            case .russian: "ロシア語"
            case .portuguese: "ポルトガル語"
            case .spanish: "スペイン語"
            case .italian: "イタリア語"
            }
        case .korean:
            switch self {
            case .automatic: "자동"
            case .chinese: "중국어"
            case .beijingDialect: "베이징 방언"
            case .sichuanDialect: "쓰촨 방언"
            case .english: "영어"
            case .japanese: "일본어"
            case .korean: "한국어"
            case .german: "독일어"
            case .french: "프랑스어"
            case .russian: "러시아어"
            case .portuguese: "포르투갈어"
            case .spanish: "스페인어"
            case .italian: "이탈리아어"
            }
        default:
            displayTitle(language: .english)
        }
    }
}

public extension ScriptStudioLanguageChoice {
    func title(language: AppLanguage) -> String {
        if isAutomatic {
            return ScriptStudioLanguageOption.automatic.displayTitle(language: language)
        }
        return selectedOptions.map { $0.displayTitle(language: language) }.joined(separator: " + ")
    }

    func displayLabel(for text: String, language: AppLanguage) -> String {
        if isAutomatic {
            return ScriptStudioLanguageDetector.detect(text).displayTitle(language: language)
        }
        return title(language: language)
    }

    func requestHint(for text: String, language: AppLanguage) -> String {
        let detected = ScriptStudioLanguageDetector.detect(text).displayTitle(language: language)
        if requestUsesAutoForManualCombination {
            switch AppLanguage.resolved(language) {
            case .simplifiedChinese:
                return "检测：\(detected) · \(title(language: language)) 按 Auto 送入后端"
            case .traditionalChinese:
                return "偵測：\(detected) · \(title(language: language)) 以 Auto 送入後端"
            default:
                return "Detected: \(detected) · \(title(language: language)) is sent as Auto"
            }
        }
        switch AppLanguage.resolved(language) {
        case .simplifiedChinese:
            return "检测：\(detected) · 发送：\(requestLanguage(for: text))"
        case .traditionalChinese:
            return "偵測：\(detected) · 傳送：\(requestLanguage(for: text))"
        default:
            return "Detected: \(detected) · Sent: \(requestLanguage(for: text))"
        }
    }
}

public extension PlaybackQueueControlState {
    func title(language: AppLanguage) -> String {
        switch AppLanguage.resolved(language) {
        case .english:
            isPlaying ? "Pause Full Audio" : "Play Full Audio"
        case .simplifiedChinese:
            title
        case .traditionalChinese:
            isPlaying ? "暫停全文" : "播放全文"
        case .japanese:
            isPlaying ? "全文を一時停止" : "全文を再生"
        case .korean:
            isPlaying ? "전체 오디오 일시정지" : "전체 오디오 재생"
        case .german:
            isPlaying ? "Gesamtaudio pausieren" : "Gesamtaudio abspielen"
        case .french:
            isPlaying ? "Mettre l'audio complet en pause" : "Lire l'audio complet"
        case .russian:
            isPlaying ? "Пауза полного аудио" : "Воспроизвести полное аудио"
        case .portuguese:
            isPlaying ? "Pausar áudio completo" : "Reproduzir áudio completo"
        case .spanish:
            isPlaying ? "Pausar audio completo" : "Reproducir audio completo"
        case .italian:
            isPlaying ? "Pausa audio completo" : "Riproduci audio completo"
        case .system:
            title(language: .english)
        }
    }
}
