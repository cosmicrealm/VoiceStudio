import Foundation

public enum ScriptStudioWorkflow: String, Codable, Equatable, Sendable, CaseIterable, Identifiable {
    case builtin
    case custom
    case voiceDesign
    case multiRole

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .builtin: "精品生成"
        case .custom: "克隆生成"
        case .voiceDesign: "创造生成"
        case .multiRole: "对话生成"
        }
    }

    public var modelCapability: ModelCapability {
        switch self {
        case .builtin:
            return .customVoice
        case .custom:
            return .voiceClone
        case .voiceDesign:
            return .voiceDesign
        case .multiRole:
            return .voiceClone
        }
    }

    public static func normalizedAfterVoiceLibraryRefresh(
        current: ScriptStudioWorkflow,
        voiceSource: VoiceSourceSelection
    ) -> ScriptStudioWorkflow {
        switch current {
        case .voiceDesign, .multiRole:
            return current
        case .builtin, .custom:
            return voiceSource == .builtin ? .builtin : .custom
        }
    }
}

public struct ScriptStudioPromptSet: Equatable, Sendable {
    public var deliveryStylePrompt: String
    public var voiceIdentityDescription: String
    public var editedDeliveryStylePrompt: String?
    public var editedVoiceIdentityDescription: String?

    public init(
        deliveryStylePrompt: String,
        voiceIdentityDescription: String,
        editedDeliveryStylePrompt: String? = nil,
        editedVoiceIdentityDescription: String? = nil
    ) {
        self.deliveryStylePrompt = deliveryStylePrompt
        self.voiceIdentityDescription = voiceIdentityDescription
        self.editedDeliveryStylePrompt = editedDeliveryStylePrompt
        self.editedVoiceIdentityDescription = editedVoiceIdentityDescription
    }

    public func activePrompt(for workflow: ScriptStudioWorkflow) -> String {
        switch workflow {
        case .voiceDesign:
            return firstNonEmpty(editedVoiceIdentityDescription, voiceIdentityDescription)
        case .builtin, .custom, .multiRole:
            return firstNonEmpty(editedDeliveryStylePrompt, deliveryStylePrompt)
        }
    }

    public func missingRequirement(for workflow: ScriptStudioWorkflow) -> String? {
        switch workflow {
        case .voiceDesign:
            activePrompt(for: workflow).isEmpty ? "控制指令" : nil
        case .builtin, .custom, .multiRole:
            nil
        }
    }

    private func firstNonEmpty(_ values: String?...) -> String {
        for value in values {
            let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return ""
    }
}

public struct ScriptStudioGenerationInputPreview: Equatable, Sendable {
    public var workflow: ScriptStudioWorkflow
    public var controlTitle: String
    public var synthesisTitle: String
    public var controlInstruction: String
    public var synthesisText: String
    public var segmentCount: Int

    public init(
        workflow: ScriptStudioWorkflow,
        promptSet: ScriptStudioPromptSet,
        synthesisText: String,
        segmentCount: Int
    ) {
        self.workflow = workflow
        self.controlTitle = "控制指令"
        self.synthesisTitle = "合成文本"
        self.controlInstruction = promptSet.activePrompt(for: workflow)
        self.synthesisText = synthesisText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.segmentCount = max(0, segmentCount)
    }

    public var promptKind: String {
        workflow == .multiRole ? "角色音色绑定" : "控制指令"
    }

    public var caption: String {
        if workflow == .multiRole {
            return "生成时会按角色标签选择已绑定音色，将合成文本按 \(segmentCount) 个段落送入 Base Clone 后合并。"
        }
        return "生成时会将\(promptKind)作为 instruct/prompt，并将合成文本按 \(segmentCount) 个段落送入模型。"
    }
}
