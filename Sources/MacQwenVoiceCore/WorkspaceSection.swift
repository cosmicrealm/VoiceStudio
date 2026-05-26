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
        switch self {
        case .scriptStudio: "Script Studio"
        case .premiumVoices: "精品音色"
        case .clonedVoices: "克隆音色"
        case .voiceDesign: "创造音色"
        case .textRobustness: "文本鲁棒性"
        case .scriptRewrite: "对话改写"
        case .voiceTools: "Voice Tools"
        case .models: "模型"
        case .settings: "设置"
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
