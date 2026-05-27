import Foundation

public enum WorkspaceSection: String, CaseIterable, Identifiable, Sendable {
    case scriptStudio
    case premiumVoices
    case clonedVoices
    case voiceDesign
    case textRobustness
    case scriptRewrite
    case voiceTools
    case models
    case settings

    public var id: String { rawValue }

    public var title: String {
        title(language: .simplifiedChinese)
    }

    public func title(language: AppLanguage) -> String {
        let localizer = AppLocalizer(language: language)
        return switch self {
        case .scriptStudio: localizer.text(.workspaceScriptStudio)
        case .premiumVoices: localizer.text(.workspacePremiumVoices)
        case .clonedVoices: localizer.text(.workspaceClonedVoices)
        case .voiceDesign: localizer.text(.workspaceVoiceDesign)
        case .textRobustness: localizer.text(.workspaceTextRobustness)
        case .scriptRewrite: localizer.text(.workspaceScriptRewrite)
        case .voiceTools: localizer.text(.workspaceVoiceTools)
        case .models: localizer.text(.workspaceModels)
        case .settings: localizer.text(.workspaceSettings)
        }
    }

    public var systemImage: String {
        switch self {
        case .scriptStudio: "text.quote"
        case .premiumVoices: "person.wave.2"
        case .clonedVoices: "waveform.badge.mic"
        case .voiceDesign: "sparkles"
        case .textRobustness: "checklist"
        case .scriptRewrite: "theatermasks"
        case .voiceTools: "slider.horizontal.3"
        case .models: "cpu"
        case .settings: "gearshape"
        }
    }
}
