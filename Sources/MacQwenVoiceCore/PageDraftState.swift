import Foundation

public struct ScriptStudioPageDraft: Equatable, Sendable {
    public var isMultiRoleDesignedVoicePoolExpanded: Bool
    public var isVoiceControlExpanded: Bool
    public var generationResultsPage: Int
    public var generationResultsJumpPageText: String

    public init(
        isMultiRoleDesignedVoicePoolExpanded: Bool = false,
        isVoiceControlExpanded: Bool = false,
        generationResultsPage: Int = 1,
        generationResultsJumpPageText: String = "1"
    ) {
        self.isMultiRoleDesignedVoicePoolExpanded = isMultiRoleDesignedVoicePoolExpanded
        self.isVoiceControlExpanded = isVoiceControlExpanded
        self.generationResultsPage = generationResultsPage
        self.generationResultsJumpPageText = generationResultsJumpPageText
    }
}

public struct VoiceDesignPageDraft: Equatable, Sendable {
    public var controlInstruction: String
    public var synthesisText: String
    public var language: String
    public var generatedControlInstruction: String
    public var deepSeekEnhancedInstruction: String
    public var isControlExpanded: Bool

    public init(
        controlInstruction: String = VoiceStudioDefaults.defaultVoiceDesignControlInstruction,
        synthesisText: String = "今天我们来讲一个复杂但非常有意思的技术问题。",
        language: String = "Chinese",
        generatedControlInstruction: String = "",
        deepSeekEnhancedInstruction: String = "",
        isControlExpanded: Bool = false
    ) {
        self.controlInstruction = controlInstruction
        self.synthesisText = synthesisText
        self.language = language
        self.generatedControlInstruction = generatedControlInstruction
        self.deepSeekEnhancedInstruction = deepSeekEnhancedInstruction
        self.isControlExpanded = isControlExpanded
    }
}

public struct ScriptRewritePageDraft: Equatable, Sendable {
    public var sourceText: String
    public var contextSummary: String
    public var stylePrompt: String
    public var rewriteResult: DeepSeekScriptRewriteResult?

    public init(
        sourceText: String = "",
        contextSummary: String = "",
        stylePrompt: String = "科幻、克制、沉浸式",
        rewriteResult: DeepSeekScriptRewriteResult? = nil
    ) {
        self.sourceText = sourceText
        self.contextSummary = contextSummary
        self.stylePrompt = stylePrompt
        self.rewriteResult = rewriteResult
    }
}

public struct VoiceToolsPageDraft: Equatable, Sendable {
    public var outputName: String

    public init(outputName: String = "voice-tools-merged.webm") {
        self.outputName = outputName
    }
}

public struct ClonedVoicesPageDraft: Equatable, Sendable {
    public var cloneName: String
    public var isTranscriptExamplesExpanded: Bool

    public init(
        cloneName: String = "我的克隆音色",
        isTranscriptExamplesExpanded: Bool = false
    ) {
        self.cloneName = cloneName
        self.isTranscriptExamplesExpanded = isTranscriptExamplesExpanded
    }
}
