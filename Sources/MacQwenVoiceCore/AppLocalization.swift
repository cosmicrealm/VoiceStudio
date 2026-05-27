import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case german = "de"
    case french = "fr"
    case russian = "ru"
    case portuguese = "pt"
    case spanish = "es"
    case italian = "it"

    public var id: String { rawValue }

    public static var interfaceLanguages: [AppLanguage] {
        allCases.filter { $0 != .system }
    }

    public var displayName: String {
        switch self {
        case .system: "System"
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .german: "Deutsch"
        case .french: "Français"
        case .russian: "Русский"
        case .portuguese: "Português"
        case .spanish: "Español"
        case .italian: "Italiano"
        }
    }

    public static func resolved(
        _ selection: AppLanguage = .system,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> AppLanguage {
        guard selection == .system else { return selection }
        return resolved(from: preferredLanguages)
    }

    public static func resolved(from preferredLanguages: [String]) -> AppLanguage {
        for raw in preferredLanguages {
            let normalized = raw.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalized.hasPrefix("zh-hant") || normalized.contains("-tw") || normalized.contains("-hk") || normalized.contains("-mo") {
                return .traditionalChinese
            }
            if normalized.hasPrefix("zh") {
                return .simplifiedChinese
            }
            if normalized.hasPrefix("ja") { return .japanese }
            if normalized.hasPrefix("ko") { return .korean }
            if normalized.hasPrefix("de") { return .german }
            if normalized.hasPrefix("fr") { return .french }
            if normalized.hasPrefix("ru") { return .russian }
            if normalized.hasPrefix("pt") { return .portuguese }
            if normalized.hasPrefix("es") { return .spanish }
            if normalized.hasPrefix("it") { return .italian }
            if normalized.hasPrefix("en") { return .english }
        }
        return .english
    }
}

public enum AppLanguagePreference {
    public static let key = "VoiceStudio.appLanguage"

    public static func load(defaults: UserDefaults = .standard) -> AppLanguage {
        guard let raw = defaults.string(forKey: key),
              let language = AppLanguage(rawValue: raw) else {
            return .system
        }
        return language
    }

    public static func save(_ language: AppLanguage, defaults: UserDefaults = .standard) {
        defaults.set(language.rawValue, forKey: key)
    }

    public static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}

public enum AppLocalizationKey: String, CaseIterable, Sendable {
    case appTagline
    case workspaceScriptStudio
    case workspacePremiumVoices
    case workspaceClonedVoices
    case workspaceVoiceDesign
    case workspaceTextRobustness
    case workspaceScriptRewrite
    case workspaceVoiceTools
    case workspaceModels
    case workspaceSettings
    case settingsTitle
    case settingsSubtitle
    case settingsDeepSeekConfigured
    case settingsDeepSeekUnconfigured
    case settingsInterfaceLanguageTitle
    case settingsInterfaceLanguageSubtitle
    case settingsInterfaceLanguageDescription
    case settingsOnlineModelConfigTitle
    case settingsOnlineModelConfigSubtitle
    case settingsDeepSeekConfigSubtitle
    case pagePremiumTitle
    case pagePremiumSubtitle
    case pagePremiumUseForGeneration
    case pageClonedTitle
    case pageClonedSubtitle
    case pageVoiceDesignModelTitle
    case pageVoiceDesignModelSubtitle
    case pageVoiceDesignInputTitle
    case pageVoiceDesignInputSubtitle
    case pageTextRobustnessTitle
    case pageTextRobustnessSubtitle
    case pageTextRobustnessLoadScriptStudio
    case pageScriptRewriteTitle
    case pageScriptRewriteSubtitle
    case pageScriptRewriteDeepSeekOnce
    case pageScriptRewriteGenerating
    case pageScriptRewriteGenerateScript
    case pageVoiceToolsSubtitle
    case pageVoiceToolsLocalProcessing
    case generationResultsTitle
    case generationResultsSubtitleFormat
    case generationRunningTitle
    case generationEmptyTitle
    case generationEmptySubtitle
    case generationPreparing
    case generationPromptFormat
    case generationPromptUnset
    case generationShowDetails
    case generationHideDetails
    case deepSeekConfigTitle
    case deepSeekAPIKeyPlaceholder
    case deepSeekPaste
    case deepSeekSaveKey
    case deepSeekConfiguredReady
    case deepSeekNotConfigured
    case modelWorkspaceTitle
    case modelDefaultWorkspace
    case modelCustomWorkspace
    case modelDefaultPathFormat
    case modelChooseWorkspace
    case modelResetDefault
    case modelOpenInFinder
    case modelWorkspaceDescription
    case modelRuntimeHealth
    case modelRecheck
    case modelDownloadSource
    case modelCustomEndpointPlaceholder
    case modelCurrentSourceOfficial
    case modelCurrentSourceFormat
    case modelLiteBundleTitle
    case modelLiteBundleNote
    case modelProBundleTitle
    case modelProBundleNote
    case modelDesignBundleTitle
    case modelDesignBundleNote
    case modelInstalled
    case modelDownload
    case modelUseDefaultPath
    case modelChooseLocalPath
    case modelPrecisionTitle
    case modelCurrentValueFormat
    case modelUseThisVersion
    case modelUsingThisVersion
    case modelMissing
    case modelReady
    case runtimeInstallFirstUse
    case runtimeInstallAudioToolWarning
    case runtimeInstallDownloadToolWarning
    case runtimeInstallSSLHint
    case runtimeInstallInstalling
    case runtimeInstallRepair
    case runtimeInstallProgress
    case runtimeInstallWaitingOutput
    case runtimeInstallFullLog
    case runtimeOptionalExtensions
    case runtimeInstallNotStarted
    case runtimeInstallPreparing
    case runtimeInstallCompleted
    case runtimeInstallFailed
    case runtimeInstallMissingScriptStatus
    case runtimeInstallMissingScriptLog
    case runtimeStatusRealInference
    case runtimeStatusModelNotReady
    case runtimeStatusUnavailable
    case runtimeStatusDownloadToolMissing
    case runtimeStatusAudioToolMissing
    case runtimeStatusNeedsRepair
    case statusReady
    case statusRuntimeUnknown
    case statusRuntimeCheckFailedFormat
    case commonClear
    case commonPlay
    case commonPause
    case commonExport
    case commonDelete
    case commonCancel
    case commonSave
    case commonOpenSettings
    case commonAddAudio
    case commonOutputFileName
    case commonPreview
    case commonMoveUp
    case commonMoveDown
    case commonJumpTo
    case commonPageNumber
    case commonJump
    case commonConfigured
    case commonNotConfigured
    case commonOfficialSource
    case commonHFMirror
    case commonMissing
    case commonClearSelection
    case scriptWorkflow
    case scriptGenerationModel
    case scriptVoice
    case scriptNoReusableVoice
    case scriptSelectReusableVoice
    case scriptRecordedClonedVoices
    case scriptDesignedVoices
    case scriptModelInputTitle
    case scriptVoiceInput
    case scriptStopVoiceInput
    case scriptVoiceInputHelp
    case scriptMissingFormat
    case scriptVoiceControlTitle
    case scriptVoiceControlSubtitle
    case scriptExpand
    case scriptCollapse
    case scriptBoundReferenceAudio
    case scriptReferenceTranscript
    case scriptReferenceTranscriptNote
    case scriptRoleVoiceBindingTitle
    case scriptRoleVoiceBindingSubtitle
    case scriptRoleVoiceRoute
    case scriptRoleVoiceEmptyHint
    case scriptDesignedVoicePool
    case scriptNoDesignedVoiceHint
    case scriptMissingRefText
    case scriptUnboundVoice
    case scriptRefTextFormat
    case scriptBindVoice
    case scriptUnbound
    case scriptSelectedDesignedVoices
    case scriptOtherDesignedVoices
    case scriptGenerationControlTitle
    case scriptSynthesisText
    case scriptGenerationControlPlaceholder
    case scriptFinalControlInstruction
    case scriptRandomGenerate
    case scriptRestoreDefaultInstruction
    case scriptCloneNoInstructionTitle
    case scriptCloneNoInstructionSubtitle
    case scriptGenerateFullText
    case scriptCancelQueue
    case scriptExportFullText
    case scriptMerging
    case scriptMergedFullWebM
    case scriptMultiRoleSynthesisHint
    case scriptDefaultSynthesisHintFormat
    case scriptModelInputSubtitleMultiRole
    case scriptModelInputSubtitleRoleWarning
    case scriptModelInputSubtitleBuiltin
    case scriptModelInputSubtitleCustom
    case scriptModelInputSubtitleVoiceDesign
    case scriptRouteMultiRole
    case scriptRouteRoleWarning
    case scriptRouteBuiltin
    case scriptRouteCustom
    case scriptRouteVoiceDesign
    case scriptApplyToInstruction
    case scriptSupplementalVoiceIdentity
    case scriptSupplementalPerformance
    case scriptChooseAttributeFormat
    case scriptNotSpecified
    case voiceToolsMergeTitle
    case voiceToolsMergeSubtitle
    case voiceToolsMergeButton
    case voiceToolsMerging
    case voiceToolsEmptyTitle
    case voiceToolsEmptySubtitle
    case voiceToolsRemove
    case voiceToolsResultTitle
    case voiceToolsResultSubtitle
    case voiceToolsPlayMerged
    case voiceToolsPauseMerged
    case voiceToolsResultEmpty
    case cloneDeleteTitle
    case cloneDeleteRecordOnly
    case cloneDeleteRecordAndFiles
    case cloneDeleteMessage
    case cloneCountFormat
    case cloneTranscriptTitle
    case cloneTranscriptSubtitle
    case cloneTranscriptPlaceholder
    case cloneFillFromScript
    case cloneTranscriptExamplesTitle
    case cloneTranscriptExamplesSubtitle
    case cloneTranscriptExampleApplied
    case cloneExamplesCountFormat
    case cloneReferenceAudioTitle
    case cloneReferenceAudioSubtitle
    case cloneImportAudio
    case cloneRecordAudio
    case cloneStopRecording
    case clonePlayReference
    case clonePauseReference
    case cloneDeleteReferenceAudio
    case cloneSaveAsVoice
    case cloneCanSave
    case cloneMissingFormat
    case cloneReferenceAudioPath
    case cloneReferenceAudioMissing
    case cloneReferenceAudioReady
    case cloneDurationFormat
    case cloneSavedTitle
    case cloneSavedSubtitle
    case cloneEmptySaved
    case cloneMissingRecordedAudio
    case cloneUseForGeneration
    case cloneGenerateTestSentence
    case cloneRename
    case cloneSaveSheetSubtitle
    case cloneVoiceNamePlaceholder
    case clonePurposePlaceholder
    case cloneCanSaveSheet
    case cloneRenameTitle
    case cloneRenamePlaceholder
    case cloneReferenceAudioRequirement
    case cloneReferenceTranscriptRequirement
    case cloneVoiceNameRequirement
    case clonePurposeRequirement
    case designDeleteTitle
    case designLanguage
    case designInstructionTitle
    case designInstructionSubtitle
    case designSynthesisTitle
    case designSynthesisSubtitle
    case designGenerating
    case designGenerateReferenceVoice
    case designPlayReferenceVoice
    case designPauseReferenceVoice
    case designSaveAsVoice
    case designEnhanceControlTitle
    case designEnhanceControlSubtitle
    case designControlTypeSubtitle
    case designGenerateInitialInstruction
    case designApplyInitialInstruction
    case designInitialInstructionTitle
    case designInitialInstructionSubtitle
    case designEnhancing
    case designUseDeepSeekEnhance
    case designApplyEnhancedInstruction
    case designDeepSeekInstructionTitle
    case designDeepSeekInstructionSubtitle
    case designDeepSeekConfiguredHint
    case designDeepSeekMissingHint
    case designGenerationProgress
    case designSavedTitle
    case designSavedSubtitle
    case designEmptySaved
    case designPreviewReference
    case designPausePreviewReference
    case designSaveRoleTitle
    case designSaveRoleSubtitle
    case designSaveNamePlaceholder
    case designRenameTitle
    case designStatusAppliedInitial
    case designStatusAppliedEnhanced
    case designStatusNeedInstruction
    case designDeepSeekPurpose
    case designDeepSeekControlType
    case designNameEmpty
    case designNameDuplicate
    case rewriteSourceTitle
    case rewriteSourceSubtitle
    case rewriteControlTitle
    case rewriteControlSubtitle
    case rewriteContextPlaceholder
    case rewriteStylePlaceholder
    case rewriteDeepSeekConfiguredHint
    case rewriteDeepSeekMissingHint
    case rewriteResultTitle
    case rewriteResultSubtitle
    case rewriteApplyToScriptStudio
    case rewriteRolePreviewTitle
    case rewriteRolePreviewSubtitle
    case rewriteNoRoles
    case rewriteNoVoiceHint
    case rewriteEmptyHint
    case workspaceInitializing
    case workspaceNotInitialized
    case workspaceUseDefault
    case workspaceOpenLocation
    case premiumSpeakerCountFormat
    case premiumTemplateNatural
    case premiumTemplateNaturalInstruction
    case premiumTemplateEmotional
    case premiumTemplateEmotionalInstruction
    case premiumTemplateSlowClear
    case premiumTemplateSlowClearInstruction
    case premiumTemplateCharacter
    case premiumTemplateCharacterInstruction
}

public struct AppLocalizer: Sendable {
    public let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = AppLanguage.resolved(language)
    }

    public func text(_ key: AppLocalizationKey) -> String {
        Self.translations[language]?[key] ?? Self.translations[.english]?[key] ?? key.rawValue
    }

    private static let translations: [AppLanguage: [AppLocalizationKey: String]] = {
        var table: [AppLanguage: [AppLocalizationKey: String]] = [:]
        let english: [AppLocalizationKey: String] = [
            .appTagline: "Offline Qwen3-TTS Creator Studio",
            .workspaceScriptStudio: "Script Studio",
            .workspacePremiumVoices: "Premium Voices",
            .workspaceClonedVoices: "Cloned Voices",
            .workspaceVoiceDesign: "Voice Design",
            .workspaceTextRobustness: "Text Robustness",
            .workspaceScriptRewrite: "Dialogue Rewrite",
            .workspaceVoiceTools: "Voice Tools",
            .workspaceModels: "Models",
            .workspaceSettings: "Settings",
            .settingsTitle: "Settings",
            .settingsSubtitle: "Manage connected AI helpers, workflow enhancements, local configuration, and app language.",
            .settingsDeepSeekConfigured: "DeepSeek configured",
            .settingsDeepSeekUnconfigured: "DeepSeek not configured",
            .settingsInterfaceLanguageTitle: "Interface Language",
            .settingsInterfaceLanguageSubtitle: "Choose the language used by Voice Studio controls and status messages.",
            .settingsInterfaceLanguageDescription: "This only changes the app interface. It does not change TTS request language, project text, prompts, model names, or generated audio content.",
            .settingsOnlineModelConfigTitle: "Connected Model Settings",
            .settingsOnlineModelConfigSubtitle: "DeepSeek API key is used for voice instruction enhancement and dialogue rewrite. TTS inference still runs locally.",
            .settingsDeepSeekConfigSubtitle: "The API key is saved only in the current workspace config file; saving an empty value clears the local key.",
            .pagePremiumTitle: "CustomVoice Premium Voices",
            .pagePremiumSubtitle: "For quick narration, style control, and first-run auditions.",
            .pagePremiumUseForGeneration: "Use for Generation",
            .pageClonedTitle: "Local Voice Cloning",
            .pageClonedSubtitle: "Record authorized reference audio and a matching transcript, then reuse the saved voice in clone or dialogue generation.",
            .pageVoiceDesignModelTitle: "VoiceDesign Model",
            .pageVoiceDesignModelSubtitle: "Natural language voice creation uses the 1.7B VoiceDesign model.",
            .pageVoiceDesignInputTitle: "VoiceDesign Main Input",
            .pageVoiceDesignInputSubtitle: "Language, voice instruction, and synthesis text are sent directly to 1.7B VoiceDesign.",
            .pageTextRobustnessTitle: "Text Robustness Samples",
            .pageTextRobustnessSubtitle: "Quickly check generation stability for symbols, pinyin, formulas, and mixed-language text.",
            .pageTextRobustnessLoadScriptStudio: "Load into Script Studio",
            .pageScriptRewriteTitle: "Dialogue Rewrite",
            .pageScriptRewriteSubtitle: "Rewrite prose or long text into a Script Studio dialogue script with Narrator and Character lines.",
            .pageScriptRewriteDeepSeekOnce: "DeepSeek Rewrite",
            .pageScriptRewriteGenerating: "Rewriting",
            .pageScriptRewriteGenerateScript: "Generate Dialogue Script",
            .pageVoiceToolsSubtitle: "Standalone local audio tools. Import common formats, normalize them, and merge in order.",
            .pageVoiceToolsLocalProcessing: "Local Processing",
            .generationResultsTitle: "Generation Results",
            .generationResultsSubtitleFormat: "%@ items · %@ per page",
            .generationRunningTitle: "Generating",
            .generationEmptyTitle: "No generation results yet",
            .generationEmptySubtitle: "Click Generate Full Text on the left. New results will appear here.",
            .generationPreparing: "Preparing generation",
            .generationPromptFormat: "prompt: %@",
            .generationPromptUnset: "Not set",
            .generationShowDetails: "Show Details",
            .generationHideDetails: "Hide Details",
            .deepSeekConfigTitle: "DeepSeek Settings",
            .deepSeekAPIKeyPlaceholder: "DeepSeek API key",
            .deepSeekPaste: "Paste",
            .deepSeekSaveKey: "Save Key",
            .deepSeekConfiguredReady: "Configured, online enhancement available",
            .deepSeekNotConfigured: "Not configured",
            .modelWorkspaceTitle: "Workspace",
            .modelDefaultWorkspace: "Default workspace",
            .modelCustomWorkspace: "Custom workspace",
            .modelDefaultPathFormat: "Default path: %@",
            .modelChooseWorkspace: "Choose Workspace",
            .modelResetDefault: "Reset Default",
            .modelOpenInFinder: "Open in Finder",
            .modelWorkspaceDescription: "Models are downloaded to the current workspace/models directory. You can switch the whole workspace or choose a downloaded local path for each model.",
            .modelRuntimeHealth: "Runtime Health",
            .modelRecheck: "Recheck",
            .modelDownloadSource: "Model Download Source",
            .modelCustomEndpointPlaceholder: "Custom HF_ENDPOINT, leave empty for official source",
            .modelCurrentSourceOfficial: "Current source: Hugging Face official source",
            .modelCurrentSourceFormat: "Current source: %@",
            .modelLiteBundleTitle: "Lite Bundle: 0.6B CustomVoice + Base",
            .modelLiteBundleNote: "Preview and baseline models first; CustomVoice is used for premium generation, Base for clone and dialogue generation.",
            .modelProBundleTitle: "Pro Bundle: 1.7B CustomVoice + Base",
            .modelProBundleNote: "Prioritizes export quality; CustomVoice has stronger controllability, Base has higher clone quality.",
            .modelDesignBundleTitle: "Design Bundle: 1.7B VoiceDesign",
            .modelDesignBundleNote: "Create voices from natural language descriptions, then save them as reusable character voices.",
            .modelInstalled: "Installed",
            .modelDownload: "Download",
            .modelUseDefaultPath: "Use Default Path",
            .modelChooseLocalPath: "Choose Local Path",
            .modelPrecisionTitle: "VoiceDesign precision/version",
            .modelCurrentValueFormat: "Current: %@",
            .modelUseThisVersion: "Use This Version",
            .modelUsingThisVersion: "Using",
            .modelMissing: "Missing",
            .modelReady: "Ready",
            .runtimeInstallFirstUse: "On a new Mac, install the local runtime first: Python 3.12, MLX, mlx-audio, transformers, Hugging Face CLI, and ffmpeg.",
            .runtimeInstallAudioToolWarning: "MLX inference is available, but ffmpeg is missing. Install Homebrew and run brew install python@3.12 ffmpeg, or use install/repair.",
            .runtimeInstallDownloadToolWarning: "Hugging Face CLI command hf is missing. Install/repair will run pip install -U \"huggingface_hub[cli]\" hf_transfer and add hf to Voice Studio runtime PATH.",
            .runtimeInstallSSLHint: "If the log mentions LibreSSL / urllib3 / SSL, the system Python is usually too old. The installer prefers Homebrew python@3.12.",
            .runtimeInstallInstalling: "Installing runtime",
            .runtimeInstallRepair: "Install/Repair Runtime",
            .runtimeInstallProgress: "Install Progress",
            .runtimeInstallWaitingOutput: "Waiting for installer output...",
            .runtimeInstallFullLog: "Show Full Install Log",
            .runtimeOptionalExtensions: "Optional Extensions",
            .runtimeInstallNotStarted: "Not started",
            .runtimeInstallPreparing: "Preparing installation",
            .runtimeInstallCompleted: "Installation completed",
            .runtimeInstallFailed: "Installation failed",
            .runtimeInstallMissingScriptStatus: "Runtime installer script not found",
            .runtimeInstallMissingScriptLog: "scripts/install_runtime.sh was not found. Download the latest Voice Studio build and try again.",
            .runtimeStatusRealInference: "Real Inference",
            .runtimeStatusModelNotReady: "Model Not Ready",
            .runtimeStatusUnavailable: "Runtime Unavailable",
            .runtimeStatusDownloadToolMissing: "Download Tool Missing",
            .runtimeStatusAudioToolMissing: "Audio Tool Missing",
            .runtimeStatusNeedsRepair: "Runtime Needs Repair",
            .statusReady: "Ready",
            .statusRuntimeUnknown: "Runtime status is not recognizable",
            .statusRuntimeCheckFailedFormat: "Runtime check failed: %@",
            .commonClear: "Clear",
            .commonPlay: "Play",
            .commonPause: "Pause",
            .commonExport: "Export",
            .commonDelete: "Delete",
            .commonCancel: "Cancel",
            .commonSave: "Save",
            .commonOpenSettings: "Open Settings",
            .commonAddAudio: "Add Audio",
            .commonOutputFileName: "Output File Name",
            .commonPreview: "Preview",
            .commonMoveUp: "Move Up",
            .commonMoveDown: "Move Down",
            .commonJumpTo: "Jump to",
            .commonPageNumber: "Page",
            .commonJump: "Jump",
            .commonConfigured: "Configured",
            .commonNotConfigured: "Not configured",
            .commonOfficialSource: "Official Source",
            .commonHFMirror: "HF Mirror",
            .commonMissing: "Missing",
            .commonClearSelection: "Clear",
            .scriptWorkflow: "Workflow",
            .scriptGenerationModel: "Generation Model",
            .scriptVoice: "Voice",
            .scriptNoReusableVoice: "No reusable voices",
            .scriptSelectReusableVoice: "Select reusable voice",
            .scriptRecordedClonedVoices: "Recorded / imported cloned voices",
            .scriptDesignedVoices: "VoiceDesign voices",
            .scriptModelInputTitle: "Model Input",
            .scriptVoiceInput: "Voice Input",
            .scriptStopVoiceInput: "Stop Voice Input",
            .scriptVoiceInputHelp: "Use macOS speech recognition to write microphone input into the synthesis text.",
            .scriptMissingFormat: "Missing: %@",
            .scriptVoiceControlTitle: "Voice Control",
            .scriptVoiceControlSubtitle: "Select or edit control attributes, then apply them to the instruction field.",
            .scriptExpand: "Expand",
            .scriptCollapse: "Collapse",
            .scriptBoundReferenceAudio: "Bound Reference Audio",
            .scriptReferenceTranscript: "Reference Transcript",
            .scriptReferenceTranscriptNote: "Base reuses the reference transcript saved with the voice to avoid ref_audio / ref_text mismatch.",
            .scriptRoleVoiceBindingTitle: "Role Voice Binding",
            .scriptRoleVoiceBindingSubtitle: "Each role must bind a saved cloned or created voice; Base reuses ref_audio/ref_text line by line.",
            .scriptRoleVoiceRoute: "Role Voices + Base",
            .scriptRoleVoiceEmptyHint: "Write lines as \"Role: dialogue\" in the synthesis text. The system will parse roles and ask you to bind a saved voice for each one.",
            .scriptDesignedVoicePool: "Created Voice Pool",
            .scriptNoDesignedVoiceHint: "No created voices yet. Save character voices in Voice Design first, then return here to select them.",
            .scriptMissingRefText: "Missing ref_text",
            .scriptUnboundVoice: "Unbound voice",
            .scriptRefTextFormat: "ref_text: %@",
            .scriptBindVoice: "Bind Voice",
            .scriptUnbound: "Unbound",
            .scriptSelectedDesignedVoices: "Selected created voices",
            .scriptOtherDesignedVoices: "Other created voices",
            .scriptGenerationControlTitle: "Instruction Control",
            .scriptSynthesisText: "Synthesis Text",
            .scriptGenerationControlPlaceholder: "No control instruction set; the selected voice default style will be used.",
            .scriptFinalControlInstruction: "The final control instruction sent to the model",
            .scriptRandomGenerate: "Randomize",
            .scriptRestoreDefaultInstruction: "Restore Default Instruction",
            .scriptCloneNoInstructionTitle: "Clone generation does not use instruction control",
            .scriptCloneNoInstructionSubtitle: "The voice comes from RefAudio and RefText. Generation reuses the selected voice's bound reference audio and transcript without sending an extra control instruction.",
            .scriptGenerateFullText: "Generate Full Text",
            .scriptCancelQueue: "Cancel Queue",
            .scriptExportFullText: "Export Full Audio",
            .scriptMerging: "Merging",
            .scriptMergedFullWebM: "Merged full WebM",
            .scriptMultiRoleSynthesisHint: "Write dialogue as \"Role: line\". During generation, role labels are removed and each line is synthesized through Base with the bound voice, then merged into a full WebM.",
            .scriptDefaultSynthesisHintFormat: "Internally split into %@ generation segments; full-text generation merges them into a complete WebM.",
            .scriptModelInputSubtitleMultiRole: "Dialogue generation: only bound role voices are used, and Base synthesizes each line before merging a full WebM.",
            .scriptModelInputSubtitleRoleWarning: "Multi-role script detected: switch to Dialogue Generation to avoid voice drift.",
            .scriptModelInputSubtitleBuiltin: "CustomVoice: confirm language, edit instruction control, and use the voice selected above.",
            .scriptModelInputSubtitleCustom: "Base Clone: confirm language and use the bound reference group from the reusable voice.",
            .scriptModelInputSubtitleVoiceDesign: "VoiceDesign: confirm language and edit the voice design instruction.",
            .scriptRouteMultiRole: "Dialogue Generation: role voices + Base line-by-line reuse and merge",
            .scriptRouteRoleWarning: "Role script detected: switch to Dialogue Generation",
            .scriptRouteBuiltin: "CustomVoice: premium speaker with style control",
            .scriptRouteCustom: "Base Clone: reuse a cloned or created voice",
            .scriptRouteVoiceDesign: "VoiceDesign: create a voice directly from natural language",
            .scriptApplyToInstruction: "Apply to Instruction Control",
            .scriptSupplementalVoiceIdentity: "Additional Voice Identity",
            .scriptSupplementalPerformance: "Additional Performance Direction",
            .scriptChooseAttributeFormat: "Choose %@",
            .scriptNotSpecified: "Not specified",
            .voiceToolsMergeTitle: "Merge Audio in Order",
            .voiceToolsMergeSubtitle: "Select multiple audio files and merge them in list order. Supports wav, mp3, m4a, aac, flac, ogg, opus, aiff, caf, and webm with case-insensitive extensions.",
            .voiceToolsMergeButton: "Merge to Full Audio",
            .voiceToolsMerging: "Merging",
            .voiceToolsEmptyTitle: "No audio files to merge yet",
            .voiceToolsEmptySubtitle: "Click Add Audio to select files. If the order is wrong, use Move Up / Move Down in the list.",
            .voiceToolsRemove: "Remove",
            .voiceToolsResultTitle: "Merge Result",
            .voiceToolsResultSubtitle: "The generated full audio is saved in the current workspace outputs directory.",
            .voiceToolsPlayMerged: "Play Full Audio",
            .voiceToolsPauseMerged: "Pause Full Audio",
            .voiceToolsResultEmpty: "After merging, the full audio path will appear here with playback and export controls.",
            .cloneDeleteTitle: "Delete cloned voice?",
            .cloneDeleteRecordOnly: "Delete voice record only",
            .cloneDeleteRecordAndFiles: "Delete record and linked files",
            .cloneDeleteMessage: "Deleting files only affects reference audio and clone prompts inside the Voice Studio workspace.",
            .cloneCountFormat: "%@ cloned voices",
            .cloneTranscriptTitle: "1. Reference Transcript",
            .cloneTranscriptSubtitle: "Edit this text directly. The recording should match it as closely as possible.",
            .cloneTranscriptPlaceholder: "Make the recording match this text word for word",
            .cloneFillFromScript: "Fill from current script",
            .cloneTranscriptExamplesTitle: "Reference Transcript Examples",
            .cloneTranscriptExamplesSubtitle: "Optional. Click a candidate sentence to replace the step 1 text.",
            .cloneTranscriptExampleApplied: "Reference transcript example applied",
            .cloneExamplesCountFormat: "%@ items",
            .cloneReferenceAudioTitle: "2. Reference Audio",
            .cloneReferenceAudioSubtitle: "Import or record, audition it first, then save as a cloned voice after confirming transcript alignment.",
            .cloneImportAudio: "Import Audio",
            .cloneRecordAudio: "Record Reference Audio",
            .cloneStopRecording: "Stop Recording",
            .clonePlayReference: "Play Reference Audio",
            .clonePauseReference: "Pause Reference Audio",
            .cloneDeleteReferenceAudio: "Delete Current Reference Audio",
            .cloneSaveAsVoice: "Save as Cloned Voice",
            .cloneCanSave: "Ready to save",
            .cloneMissingFormat: "Missing: %@",
            .cloneReferenceAudioPath: "Reference audio path",
            .cloneReferenceAudioMissing: "No reference audio yet",
            .cloneReferenceAudioReady: "Reference audio added",
            .cloneDurationFormat: "Duration: %@",
            .cloneSavedTitle: "Saved Cloned Voices",
            .cloneSavedSubtitle: "Manage, rename, delete, or send voices to Voice Studio.",
            .cloneEmptySaved: "No cloned voices yet. They will appear here after you complete the reference transcript and audio.",
            .cloneMissingRecordedAudio: "No reference audio recorded",
            .cloneUseForGeneration: "Use for Generation",
            .cloneGenerateTestSentence: "Generate Test Sentence",
            .cloneRename: "Rename",
            .cloneSaveSheetSubtitle: "This name will be saved with the current reference audio and transcript.",
            .cloneVoiceNamePlaceholder: "Cloned voice name",
            .clonePurposePlaceholder: "Authorization purpose",
            .cloneCanSaveSheet: "Ready to save as cloned voice",
            .cloneRenameTitle: "Rename Cloned Voice",
            .cloneRenamePlaceholder: "New voice name",
            .cloneReferenceAudioRequirement: "reference audio",
            .cloneReferenceTranscriptRequirement: "reference transcript",
            .cloneVoiceNameRequirement: "voice name",
            .clonePurposeRequirement: "authorization purpose",
            .designDeleteTitle: "Delete created voice?",
            .designLanguage: "Language",
            .designInstructionTitle: "Instruction Control",
            .designInstructionSubtitle: "Sent directly to VoiceDesign as instruct/prompt.",
            .designSynthesisTitle: "Synthesis / Audition Text",
            .designSynthesisSubtitle: "The text the model will read. When saved as a character voice, this becomes the reference text.",
            .designGenerating: "Generating",
            .designGenerateReferenceVoice: "Generate Reference Voice",
            .designPlayReferenceVoice: "Play Reference Voice",
            .designPauseReferenceVoice: "Pause Reference Voice",
            .designSaveAsVoice: "Save as Voice",
            .designEnhanceControlTitle: "Enhanced Instruction Control",
            .designEnhanceControlSubtitle: "Control types and DeepSeek only create candidate instructions. Apply one to write it back to the main instruction field.",
            .designControlTypeSubtitle: "Expand to select and edit VoiceDesign control attributes.",
            .designGenerateInitialInstruction: "Generate Initial Instruction",
            .designApplyInitialInstruction: "Apply Initial Instruction",
            .designInitialInstructionTitle: "Initial Instruction",
            .designInitialInstructionSubtitle: "Generated from control type combinations and editable; it does not change the main input until applied.",
            .designEnhancing: "Enhancing",
            .designUseDeepSeekEnhance: "Enhance with DeepSeek",
            .designApplyEnhancedInstruction: "Apply Enhanced Instruction",
            .designDeepSeekInstructionTitle: "DeepSeek Enhanced Instruction",
            .designDeepSeekInstructionSubtitle: "DeepSeek online enhancement output appears here. Apply it only after review.",
            .designDeepSeekConfiguredHint: "Online enhancement can generate candidate control instructions.",
            .designDeepSeekMissingHint: "Configure the API key in Settings to enable online enhancement.",
            .designGenerationProgress: "Generation Progress",
            .designSavedTitle: "Saved Created Voices",
            .designSavedSubtitle: "Manage, rename, delete, or send voices to Voice Studio.",
            .designEmptySaved: "No created voices yet. Generate a reference voice and save it to show it here.",
            .designPreviewReference: "Preview Reference",
            .designPausePreviewReference: "Pause Reference",
            .designSaveRoleTitle: "Save as Character Voice",
            .designSaveRoleSubtitle: "This name will be written to saved created voices and bound to the current reference voice and audition text.",
            .designSaveNamePlaceholder: "Voice name to save",
            .designRenameTitle: "Rename Created Voice",
            .designStatusAppliedInitial: "Applied the initial control instruction to the main input above",
            .designStatusAppliedEnhanced: "Applied the DeepSeek enhanced instruction to the main input above",
            .designStatusNeedInstruction: "Fill the main instruction field or generate an initial control instruction first",
            .designDeepSeekPurpose: "VoiceDesign voice creation",
            .designDeepSeekControlType: "VoiceDesign control instruction enhancement",
            .designNameEmpty: "Voice name cannot be empty",
            .designNameDuplicate: "Voice name already exists. Choose another name before saving.",
            .rewriteSourceTitle: "Source Text",
            .rewriteSourceSubtitle: "Paste the prose or novel excerpt to rewrite. Split long text into sections when needed.",
            .rewriteControlTitle: "Rewrite Control",
            .rewriteControlSubtitle: "These hints only affect DeepSeek rewrite and are not sent directly to the TTS model.",
            .rewriteContextPlaceholder: "Previous context summary, optional",
            .rewriteStylePlaceholder: "Role / style hint, for example: sci-fi, restrained, immersive; steady narrator, suppressed dialogue",
            .rewriteDeepSeekConfiguredHint: "Online rewrite can generate candidate dialogue scripts.",
            .rewriteDeepSeekMissingHint: "Configure the API key in Settings to enable dialogue rewrite.",
            .rewriteResultTitle: "Generated Result Preview",
            .rewriteResultSubtitle: "Review before applying to Script Studio. Applying switches automatically to Dialogue Generation.",
            .rewriteApplyToScriptStudio: "Apply to Script Studio",
            .rewriteRolePreviewTitle: "Role Prompt Preview",
            .rewriteRolePreviewSubtitle: "Used later to bind or create role voices in Dialogue Generation.",
            .rewriteNoRoles: "No roles detected yet.",
            .rewriteNoVoiceHint: "No voice suggestion provided",
            .rewriteEmptyHint: "After generation, DeepSeek role and voice suggestions will appear here.",
            .workspaceInitializing: "Initializing",
            .workspaceNotInitialized: "Workspace not initialized",
            .workspaceUseDefault: "Use Default Workspace",
            .workspaceOpenLocation: "Open Location",
            .premiumSpeakerCountFormat: "%@ speakers",
            .premiumTemplateNatural: "Natural Narration",
            .premiumTemplateNaturalInstruction: "Natural, clear, and stable, suitable for long-form narration.",
            .premiumTemplateEmotional: "Stronger Emotion",
            .premiumTemplateEmotionalInstruction: "Fuller emotion and more engaging tone while keeping articulation clear.",
            .premiumTemplateSlowClear: "Slow and Clear",
            .premiumTemplateSlowClearInstruction: "Slightly slower pace, natural pauses, and clearer emphasis on key words.",
            .premiumTemplateCharacter: "Characterful",
            .premiumTemplateCharacterInstruction: "A clear persona with stronger character presence and scene imagery."
        ]
        table[.english] = english

        table[.simplifiedChinese] = [
            .appTagline: "离线 Qwen3-TTS 创作台",
            .workspaceScriptStudio: "Script Studio",
            .workspacePremiumVoices: "精品音色",
            .workspaceClonedVoices: "克隆音色",
            .workspaceVoiceDesign: "创造音色",
            .workspaceTextRobustness: "文本鲁棒性",
            .workspaceScriptRewrite: "对话改写",
            .workspaceVoiceTools: "Voice Tools",
            .workspaceModels: "模型",
            .workspaceSettings: "设置",
            .settingsTitle: "设置",
            .settingsSubtitle: "集中管理联网大模型、工作流增强、本地配置和界面语言。",
            .settingsDeepSeekConfigured: "DeepSeek 已配置",
            .settingsDeepSeekUnconfigured: "DeepSeek 未配置",
            .settingsInterfaceLanguageTitle: "界面语言",
            .settingsInterfaceLanguageSubtitle: "选择 Voice Studio 控件和状态消息使用的语言。",
            .settingsInterfaceLanguageDescription: "这里只改变 App 界面，不改变 TTS 请求语言、项目文本、提示词、模型名或生成音频内容。",
            .settingsOnlineModelConfigTitle: "联网大模型配置",
            .settingsOnlineModelConfigSubtitle: "DeepSeek API key 用于创造音色增强、对话改写等联网辅助能力；TTS 推理仍然走本地模型。",
            .settingsDeepSeekConfigSubtitle: "API key 只保存到当前 workspace 的本地配置文件；留空保存会清除本地 key。",
            .pagePremiumTitle: "CustomVoice 精品音色",
            .pagePremiumSubtitle: "用于快速旁白、风格控制和开箱试听。",
            .pagePremiumUseForGeneration: "用于生成",
            .pageClonedTitle: "本地音色克隆",
            .pageClonedSubtitle: "录入一段授权参考音频和逐字稿，保存后在 Voice Studio 的克隆生成/对话生成中复用。",
            .pageVoiceDesignModelTitle: "VoiceDesign 模型",
            .pageVoiceDesignModelSubtitle: "自然语言声音创造使用 1.7B VoiceDesign。",
            .pageVoiceDesignInputTitle: "VoiceDesign 主输入",
            .pageVoiceDesignInputSubtitle: "这里的 language、指令控制和合成文本会直接送入 1.7B VoiceDesign。",
            .pageTextRobustnessTitle: "文本鲁棒性样例",
            .pageTextRobustnessSubtitle: "用于快速检查符号、拼音、公式、跨语言文本的生成稳定性。",
            .pageTextRobustnessLoadScriptStudio: "载入 Script Studio",
            .pageScriptRewriteTitle: "对话改写",
            .pageScriptRewriteSubtitle: "把原始小说或长文本改写成 Voice Studio 对话生成可识别的“旁白: 内容 / 角色: 台词”脚本。",
            .pageScriptRewriteDeepSeekOnce: "DeepSeek 一次改写",
            .pageScriptRewriteGenerating: "改写中",
            .pageScriptRewriteGenerateScript: "生成对话脚本",
            .pageVoiceToolsSubtitle: "独立音频工具箱；导入主流音频后统一转码并按顺序合并。",
            .pageVoiceToolsLocalProcessing: "本地处理",
            .generationResultsTitle: "生成结果",
            .generationResultsSubtitleFormat: "共 %@ 条 · 每页 %@ 条",
            .generationRunningTitle: "正在生成",
            .generationEmptyTitle: "还没有生成结果",
            .generationEmptySubtitle: "点击左侧“生成全文”后，最新生成会出现在这里。",
            .generationPreparing: "准备生成",
            .generationPromptFormat: "prompt: %@",
            .generationPromptUnset: "未设置",
            .generationShowDetails: "显示详情",
            .generationHideDetails: "收起详情",
            .deepSeekConfigTitle: "DeepSeek 配置",
            .deepSeekAPIKeyPlaceholder: "DeepSeek API key",
            .deepSeekPaste: "粘贴",
            .deepSeekSaveKey: "保存 Key",
            .deepSeekConfiguredReady: "已配置，可联网增强",
            .deepSeekNotConfigured: "未配置",
            .modelWorkspaceTitle: "工作目录",
            .modelDefaultWorkspace: "默认 workspace",
            .modelCustomWorkspace: "自定义 workspace",
            .modelDefaultPathFormat: "默认路径：%@",
            .modelChooseWorkspace: "选择 Workspace",
            .modelResetDefault: "恢复默认",
            .modelOpenInFinder: "在 Finder 打开",
            .modelWorkspaceDescription: "模型默认下载到当前 workspace/models；你也可以切换整个 workspace，或为单个模型选择已下载路径。",
            .modelRuntimeHealth: "运行时健康状态",
            .modelRecheck: "重新检查",
            .modelDownloadSource: "模型下载源",
            .modelCustomEndpointPlaceholder: "自定义 HF_ENDPOINT，可留空使用官方源",
            .modelCurrentSourceOfficial: "当前下载源：Hugging Face 官方源",
            .modelCurrentSourceFormat: "当前下载源：%@",
            .modelLiteBundleTitle: "Lite 包：0.6B CustomVoice + Base",
            .modelLiteBundleNote: "预览和基础机型优先；CustomVoice 用于精品生成，Base 用于克隆生成和对话生成。",
            .modelProBundleTitle: "Pro 包：1.7B CustomVoice + Base",
            .modelProBundleNote: "正式导出质量优先；CustomVoice 控制力更强，Base 克隆质量更高。",
            .modelDesignBundleTitle: "Design 包：1.7B VoiceDesign",
            .modelDesignBundleNote: "自然语言声音创造；满意后保存为可复用角色音色。",
            .modelInstalled: "已安装",
            .modelDownload: "下载",
            .modelUseDefaultPath: "使用默认路径",
            .modelChooseLocalPath: "选择本地路径",
            .modelPrecisionTitle: "VoiceDesign 精度/版本",
            .modelCurrentValueFormat: "当前：%@",
            .modelUseThisVersion: "使用此版本",
            .modelUsingThisVersion: "正在使用",
            .modelMissing: "未安装",
            .modelReady: "已安装",
            .runtimeInstallFirstUse: "首次在新 Mac 上使用时，需要先安装本机运行环境：Python 3.12、MLX、mlx-audio、transformers、Hugging Face CLI 和 ffmpeg。",
            .runtimeInstallAudioToolWarning: "当前 MLX 推理已经可用，但 ffmpeg 缺失。请先安装 Homebrew，再执行 brew install python@3.12 ffmpeg，或使用安装/修复。",
            .runtimeInstallDownloadToolWarning: "当前缺少 Hugging Face CLI 命令 hf，模型下载会失败。安装/修复会执行 pip install -U \"huggingface_hub[cli]\" hf_transfer，并把 hf 加入 Voice Studio runtime PATH。",
            .runtimeInstallSSLHint: "如果日志出现 LibreSSL / urllib3 / SSL 相关提示，通常是系统 Python 过旧；安装器会优先使用 Homebrew python@3.12。",
            .runtimeInstallInstalling: "正在安装运行环境",
            .runtimeInstallRepair: "安装/修复运行环境",
            .runtimeInstallProgress: "安装进度",
            .runtimeInstallWaitingOutput: "等待安装输出...",
            .runtimeInstallFullLog: "查看完整安装日志",
            .runtimeOptionalExtensions: "可选扩展",
            .runtimeInstallNotStarted: "未开始",
            .runtimeInstallPreparing: "准备安装",
            .runtimeInstallCompleted: "安装完成",
            .runtimeInstallFailed: "安装失败",
            .runtimeInstallMissingScriptStatus: "未找到运行环境安装脚本",
            .runtimeInstallMissingScriptLog: "未找到 scripts/install_runtime.sh。请重新下载新版 Voice Studio。",
            .runtimeStatusRealInference: "真实推理",
            .runtimeStatusModelNotReady: "模型未就绪",
            .runtimeStatusUnavailable: "运行时不可用",
            .runtimeStatusDownloadToolMissing: "下载工具缺失",
            .runtimeStatusAudioToolMissing: "音频工具缺失",
            .runtimeStatusNeedsRepair: "运行时需修复",
            .statusReady: "准备就绪",
            .statusRuntimeUnknown: "运行时状态不可识别",
            .statusRuntimeCheckFailedFormat: "运行时检查失败：%@",
            .commonClear: "清空",
            .commonPlay: "播放",
            .commonPause: "暂停",
            .commonExport: "导出",
            .commonDelete: "删除",
            .commonCancel: "取消",
            .commonSave: "保存",
            .commonOpenSettings: "打开设置",
            .commonAddAudio: "添加音频",
            .commonOutputFileName: "输出文件名",
            .commonPreview: "试听",
            .commonMoveUp: "上移",
            .commonMoveDown: "下移",
            .commonJumpTo: "跳到",
            .commonPageNumber: "页码",
            .commonJump: "跳转",
            .commonConfigured: "已配置",
            .commonNotConfigured: "未配置",
            .commonOfficialSource: "官方源",
            .commonHFMirror: "HF Mirror",
            .commonMissing: "缺失",
            .commonClearSelection: "清空",
            .scriptWorkflow: "工作流",
            .scriptGenerationModel: "生成模型",
            .scriptVoice: "音色",
            .scriptNoReusableVoice: "暂无可复用音色",
            .scriptSelectReusableVoice: "选择可复用音色",
            .scriptRecordedClonedVoices: "录制/导入克隆音色",
            .scriptDesignedVoices: "VoiceDesign 创造音色",
            .scriptModelInputTitle: "模型输入",
            .scriptVoiceInput: "语音输入",
            .scriptStopVoiceInput: "停止语音输入",
            .scriptVoiceInputHelp: "调用 macOS 系统语音识别，把麦克风输入写入待生成文字。",
            .scriptMissingFormat: "缺失：%@",
            .scriptVoiceControlTitle: "声音控制",
            .scriptVoiceControlSubtitle: "选择或编辑控制属性后，点击应用到指令控制。",
            .scriptExpand: "展开",
            .scriptCollapse: "收起",
            .scriptBoundReferenceAudio: "已绑定参考音频",
            .scriptReferenceTranscript: "参考逐字稿",
            .scriptReferenceTranscriptNote: "Base 复用固定使用保存音色时绑定的 reference transcript，避免参考音频和逐字稿错配。",
            .scriptRoleVoiceBindingTitle: "角色音色绑定",
            .scriptRoleVoiceBindingSubtitle: "每个角色必须绑定一个已保存的克隆音色或创造音色；Base 逐句复用 ref_audio/ref_text。",
            .scriptRoleVoiceRoute: "角色音色 + Base",
            .scriptRoleVoiceEmptyHint: "在合成文本里写“角色名: 台词”。系统会解析角色列表；每个角色都需要在这里绑定已保存音色。",
            .scriptDesignedVoicePool: "创造音色池",
            .scriptNoDesignedVoiceHint: "暂无创造音色。先在左侧“创造音色”保存角色声音，再回到这里选择使用。",
            .scriptMissingRefText: "缺少 ref_text",
            .scriptUnboundVoice: "未绑定音色",
            .scriptRefTextFormat: "ref_text：%@",
            .scriptBindVoice: "绑定音色",
            .scriptUnbound: "未绑定",
            .scriptSelectedDesignedVoices: "已选创造音色",
            .scriptOtherDesignedVoices: "其他创造音色",
            .scriptGenerationControlTitle: "指令控制",
            .scriptSynthesisText: "合成文本",
            .scriptGenerationControlPlaceholder: "未设置控制指令；将使用所选音色的默认风格。",
            .scriptFinalControlInstruction: "最终送入模型的控制指令",
            .scriptRandomGenerate: "随机生成",
            .scriptRestoreDefaultInstruction: "恢复默认指令",
            .scriptCloneNoInstructionTitle: "克隆生成不使用指令控制",
            .scriptCloneNoInstructionSubtitle: "音色来自 RefAudio 和 RefText；生成时会复用所选音色绑定的参考音频和参考逐字稿，不再额外传入控制指令。",
            .scriptGenerateFullText: "生成全文",
            .scriptCancelQueue: "取消队列",
            .scriptExportFullText: "导出全文",
            .scriptMerging: "合成中",
            .scriptMergedFullWebM: "已合并完整 WebM",
            .scriptMultiRoleSynthesisHint: "用“角色名: 台词”写对话；生成时会去掉角色标签，按绑定音色逐句 Base 合成并合并为完整 WebM。",
            .scriptDefaultSynthesisHintFormat: "内部会拆成 %@ 个生成段；生成全文后会合并为完整 WebM",
            .scriptModelInputSubtitleMultiRole: "对话生成：只使用已绑定角色音色，Base 逐句合成后合并为完整 WebM。",
            .scriptModelInputSubtitleRoleWarning: "检测到多角色脚本：请切换到“对话生成”以避免角色声线漂移。",
            .scriptModelInputSubtitleBuiltin: "CustomVoice：确认 language，编辑指令控制，音色由上方选择。",
            .scriptModelInputSubtitleCustom: "Base Clone：确认 language，并使用可复用音色绑定的参考组。",
            .scriptModelInputSubtitleVoiceDesign: "VoiceDesign：确认 language，编辑声音设计指令。",
            .scriptRouteMultiRole: "对话生成：角色音色 + Base 逐句复用并合并",
            .scriptRouteRoleWarning: "检测到角色脚本：请切换到对话生成",
            .scriptRouteBuiltin: "CustomVoice：精品 speaker 与风格控制",
            .scriptRouteCustom: "Base Clone：复用克隆音色或创造音色",
            .scriptRouteVoiceDesign: "VoiceDesign：用自然语言描述直接创造声音",
            .scriptApplyToInstruction: "应用到指令控制",
            .scriptSupplementalVoiceIdentity: "补充声音身份描述",
            .scriptSupplementalPerformance: "补充演绎指令",
            .scriptChooseAttributeFormat: "选择%@",
            .scriptNotSpecified: "不指定",
            .voiceToolsMergeTitle: "按顺序合并音频",
            .voiceToolsMergeSubtitle: "选择多个音频后按列表顺序合并；支持 wav、mp3、m4a、aac、flac、ogg、opus、aiff、caf、webm，扩展名大小写不敏感。",
            .voiceToolsMergeButton: "合并为总音频",
            .voiceToolsMerging: "合并中",
            .voiceToolsEmptyTitle: "还没有待合并音频",
            .voiceToolsEmptySubtitle: "点击“添加音频”选择一组文件；如果顺序不对，可以在列表中用上移/下移调整。",
            .voiceToolsRemove: "移除",
            .voiceToolsResultTitle: "合并结果",
            .voiceToolsResultSubtitle: "生成后的总音频会保存在当前 workspace 的 outputs 目录。",
            .voiceToolsPlayMerged: "播放总音频",
            .voiceToolsPauseMerged: "暂停总音频",
            .voiceToolsResultEmpty: "合并完成后会显示总音频路径，并提供播放和导出。",
            .cloneDeleteTitle: "删除克隆音色？",
            .cloneDeleteRecordOnly: "仅删除音色记录",
            .cloneDeleteRecordAndFiles: "删除记录并删除关联文件",
            .cloneDeleteMessage: "删除文件只会处理 Voice Studio workspace 内的参考音频和 clone prompt。",
            .cloneCountFormat: "%@ 个克隆音色",
            .cloneTranscriptTitle: "1. 参考逐字稿",
            .cloneTranscriptSubtitle: "直接编辑这段文字；录音内容尽量逐字匹配。",
            .cloneTranscriptPlaceholder: "请让录音内容逐字匹配这里的文本",
            .cloneFillFromScript: "用当前旁白填入",
            .cloneTranscriptExamplesTitle: "参考逐字稿示例",
            .cloneTranscriptExamplesSubtitle: "可选。点击候选句会替换第 1 步文本。",
            .cloneTranscriptExampleApplied: "已填入参考逐字稿示例",
            .cloneExamplesCountFormat: "%@ 条",
            .cloneReferenceAudioTitle: "2. 参考音频",
            .cloneReferenceAudioSubtitle: "导入或录制后先试听，确认逐字稿匹配后保存为克隆音色。",
            .cloneImportAudio: "导入音频",
            .cloneRecordAudio: "录制参考音频",
            .cloneStopRecording: "停止录音",
            .clonePlayReference: "播放参考音频",
            .clonePauseReference: "暂停参考音频",
            .cloneDeleteReferenceAudio: "删除当前参考音频",
            .cloneSaveAsVoice: "保存为克隆音色",
            .cloneCanSave: "可保存",
            .cloneMissingFormat: "还缺：%@",
            .cloneReferenceAudioPath: "参考音频路径",
            .cloneReferenceAudioMissing: "未录入参考音频",
            .cloneReferenceAudioReady: "参考音频已录入",
            .cloneDurationFormat: "时长：%@",
            .cloneSavedTitle: "已保存克隆音色",
            .cloneSavedSubtitle: "管理、重命名、删除或发送到 Voice Studio 使用。",
            .cloneEmptySaved: "还没有克隆音色。完成左侧参考逐字稿和参考音频后会显示在这里。",
            .cloneMissingRecordedAudio: "未记录参考音频",
            .cloneUseForGeneration: "用于生成",
            .cloneGenerateTestSentence: "生成测试句",
            .cloneRename: "重命名",
            .cloneSaveSheetSubtitle: "这里的名称会写入已保存克隆音色列表，并绑定当前参考声音与逐字稿。",
            .cloneVoiceNamePlaceholder: "克隆音色名称",
            .clonePurposePlaceholder: "授权用途说明",
            .cloneCanSaveSheet: "可保存为克隆音色",
            .cloneRenameTitle: "重命名克隆音色",
            .cloneRenamePlaceholder: "新的音色名称",
            .cloneReferenceAudioRequirement: "参考音频",
            .cloneReferenceTranscriptRequirement: "参考逐字稿",
            .cloneVoiceNameRequirement: "音色名称",
            .clonePurposeRequirement: "授权用途",
            .designDeleteTitle: "删除创造音色？",
            .designLanguage: "语言",
            .designInstructionTitle: "指令控制",
            .designInstructionSubtitle: "直接作为 VoiceDesign 的 instruct/prompt 送入模型。",
            .designSynthesisTitle: "合成文本 / 试听文本",
            .designSynthesisSubtitle: "模型要朗读的正文内容；保存角色音色时会作为这次参考声音的文本。",
            .designGenerating: "生成中",
            .designGenerateReferenceVoice: "生成参考声音",
            .designPlayReferenceVoice: "播放参考声音",
            .designPauseReferenceVoice: "暂停参考声音",
            .designSaveAsVoice: "保存为音色",
            .designEnhanceControlTitle: "增强控制指令",
            .designEnhanceControlSubtitle: "控制类型和 DeepSeek 都只生成候选指令；点击应用后才会写回上方指令控制。",
            .designControlTypeSubtitle: "展开后可选择并编辑 VoiceDesign 控制属性。",
            .designGenerateInitialInstruction: "生成初始控制指令",
            .designApplyInitialInstruction: "应用初始指令",
            .designInitialInstructionTitle: "初始控制指令",
            .designInitialInstructionSubtitle: "由控制类型组合生成，可手动编辑；不会自动影响上方主输入。",
            .designEnhancing: "增强中",
            .designUseDeepSeekEnhance: "使用 DeepSeek 增强",
            .designApplyEnhancedInstruction: "应用增强指令",
            .designDeepSeekInstructionTitle: "DeepSeek 增强指令",
            .designDeepSeekInstructionSubtitle: "DeepSeek 的联网增强输出会显示在这里，确认后再应用到上方指令控制。",
            .designDeepSeekConfiguredHint: "可使用联网增强生成候选控制指令。",
            .designDeepSeekMissingHint: "在“设置”里配置 API key 后可使用联网增强。",
            .designGenerationProgress: "生成进度",
            .designSavedTitle: "已保存创造音色",
            .designSavedSubtitle: "管理、重命名、删除或发送到 Voice Studio 使用。",
            .designEmptySaved: "还没有保存的创造音色。生成参考声音并保存后会显示在这里。",
            .designPreviewReference: "试听参考音",
            .designPausePreviewReference: "暂停参考音",
            .designSaveRoleTitle: "保存为角色音色",
            .designSaveRoleSubtitle: "这里的名称会写入已保存创造音色列表，并绑定当前参考声音与试听文本。",
            .designSaveNamePlaceholder: "输入要保存的音色名称",
            .designRenameTitle: "重命名创造音色",
            .designStatusAppliedInitial: "已将初始控制指令应用到上方主输入",
            .designStatusAppliedEnhanced: "已将 DeepSeek 增强指令应用到上方主输入",
            .designStatusNeedInstruction: "请先填写上方指令控制，或生成初始控制指令",
            .designDeepSeekPurpose: "VoiceDesign 声音创造",
            .designDeepSeekControlType: "VoiceDesign 控制指令增强",
            .designNameEmpty: "音色名称不能为空",
            .designNameDuplicate: "音色名称已存在，请换一个名称再保存",
            .rewriteSourceTitle: "原始文本",
            .rewriteSourceSubtitle: "粘贴当前要改写的小说片段；长篇内容建议分段处理。",
            .rewriteControlTitle: "改写控制",
            .rewriteControlSubtitle: "这些提示只影响 DeepSeek 改写，不会直接送入 TTS 模型。",
            .rewriteContextPlaceholder: "上文摘要，可留空",
            .rewriteStylePlaceholder: "角色 / 风格提示，例如：科幻、克制、沉浸式；旁白沉稳，人物台词压抑",
            .rewriteDeepSeekConfiguredHint: "可联网生成对话脚本候选。",
            .rewriteDeepSeekMissingHint: "在“设置”里配置 API key 后可使用对话改写。",
            .rewriteResultTitle: "生成结果预览",
            .rewriteResultSubtitle: "确认后再应用到 Script Studio；应用时会自动切换到“对话生成”。",
            .rewriteApplyToScriptStudio: "应用到 Script Studio",
            .rewriteRolePreviewTitle: "角色提示预览",
            .rewriteRolePreviewSubtitle: "用于后续在对话生成中绑定或创建角色音色。",
            .rewriteNoRoles: "暂未识别到角色。",
            .rewriteNoVoiceHint: "未提供声音建议",
            .rewriteEmptyHint: "生成后会显示 DeepSeek 返回的角色和声音建议。",
            .workspaceInitializing: "初始化中",
            .workspaceNotInitialized: "Workspace 未初始化",
            .workspaceUseDefault: "使用默认 Workspace",
            .workspaceOpenLocation: "打开位置",
            .premiumSpeakerCountFormat: "%@ 个 speaker",
            .premiumTemplateNatural: "自然旁白",
            .premiumTemplateNaturalInstruction: "自然、清晰、稳定，适合长时间旁白。",
            .premiumTemplateEmotional: "情绪更强",
            .premiumTemplateEmotionalInstruction: "情绪更饱满，语气有感染力，但保持吐字清楚。",
            .premiumTemplateSlowClear: "慢速清晰",
            .premiumTemplateSlowClearInstruction: "语速偏慢，停顿自然，重点词更清晰。",
            .premiumTemplateCharacter: "角色化",
            .premiumTemplateCharacterInstruction: "带有明确 persona，语气更有角色感和画面感。"
        ]

        table[.traditionalChinese] = [
            .appTagline: "離線 Qwen3-TTS 創作台",
            .workspaceScriptStudio: "Script Studio",
            .workspacePremiumVoices: "精品音色",
            .workspaceClonedVoices: "克隆音色",
            .workspaceVoiceDesign: "創造音色",
            .workspaceTextRobustness: "文本魯棒性",
            .workspaceScriptRewrite: "對話改寫",
            .workspaceVoiceTools: "Voice Tools",
            .workspaceModels: "模型",
            .workspaceSettings: "設定",
            .settingsTitle: "設定",
            .settingsSubtitle: "集中管理聯網大模型、工作流增強、本機配置和介面語言。",
            .settingsDeepSeekConfigured: "DeepSeek 已配置",
            .settingsDeepSeekUnconfigured: "DeepSeek 未配置",
            .settingsInterfaceLanguageTitle: "介面語言",
            .settingsInterfaceLanguageSubtitle: "選擇 Voice Studio 控制項和狀態訊息使用的語言。",
            .settingsInterfaceLanguageDescription: "這裡只改變 App 介面，不改變 TTS 請求語言、專案文本、提示詞、模型名或生成音訊內容。",
            .settingsOnlineModelConfigTitle: "聯網大模型配置",
            .settingsOnlineModelConfigSubtitle: "DeepSeek API key 用於創造音色增強、對話改寫等聯網輔助能力；TTS 推理仍然使用本機模型。",
            .settingsDeepSeekConfigSubtitle: "API key 只保存到目前 workspace 的本機配置檔案；留空保存會清除本機 key。",
            .pagePremiumTitle: "CustomVoice 精品音色",
            .pagePremiumSubtitle: "用於快速旁白、風格控制和開箱試聽。",
            .pagePremiumUseForGeneration: "用於生成",
            .pageClonedTitle: "本機音色克隆",
            .pageClonedSubtitle: "錄入一段授權參考音訊和逐字稿，保存後在 Voice Studio 的克隆生成/對話生成中復用。",
            .pageVoiceDesignModelTitle: "VoiceDesign 模型",
            .pageVoiceDesignModelSubtitle: "自然語言聲音創造使用 1.7B VoiceDesign。",
            .pageVoiceDesignInputTitle: "VoiceDesign 主輸入",
            .pageVoiceDesignInputSubtitle: "這裡的 language、指令控制和合成文本會直接送入 1.7B VoiceDesign。",
            .pageTextRobustnessTitle: "文本魯棒性樣例",
            .pageTextRobustnessSubtitle: "用於快速檢查符號、拼音、公式、跨語言文本的生成穩定性。",
            .pageTextRobustnessLoadScriptStudio: "載入 Script Studio",
            .pageScriptRewriteTitle: "對話改寫",
            .pageScriptRewriteSubtitle: "把原始小說或長文本改寫成 Voice Studio 對話生成可識別的「旁白: 內容 / 角色: 台詞」腳本。",
            .pageScriptRewriteDeepSeekOnce: "DeepSeek 一次改寫",
            .pageScriptRewriteGenerating: "改寫中",
            .pageScriptRewriteGenerateScript: "生成對話腳本",
            .pageVoiceToolsSubtitle: "獨立音訊工具箱；導入主流音訊後統一轉碼並按順序合併。",
            .pageVoiceToolsLocalProcessing: "本機處理",
            .generationResultsTitle: "生成結果",
            .generationResultsSubtitleFormat: "共 %@ 條 · 每頁 %@ 條",
            .generationRunningTitle: "正在生成",
            .generationEmptyTitle: "還沒有生成結果",
            .generationEmptySubtitle: "點擊左側「生成全文」後，最新生成會出現在這裡。",
            .generationPreparing: "準備生成",
            .generationPromptFormat: "prompt: %@",
            .generationPromptUnset: "未設定",
            .generationShowDetails: "顯示詳情",
            .generationHideDetails: "收起詳情",
            .deepSeekConfigTitle: "DeepSeek 配置",
            .deepSeekAPIKeyPlaceholder: "DeepSeek API key",
            .deepSeekPaste: "貼上",
            .deepSeekSaveKey: "保存 Key",
            .deepSeekConfiguredReady: "已配置，可聯網增強",
            .deepSeekNotConfigured: "未配置",
            .modelWorkspaceTitle: "工作目錄",
            .modelDefaultWorkspace: "預設 workspace",
            .modelCustomWorkspace: "自訂 workspace",
            .modelDefaultPathFormat: "預設路徑：%@",
            .modelChooseWorkspace: "選擇 Workspace",
            .modelResetDefault: "恢復預設",
            .modelOpenInFinder: "在 Finder 打開",
            .modelWorkspaceDescription: "模型預設下載到目前 workspace/models；你也可以切換整個 workspace，或為單個模型選擇已下載路徑。",
            .modelRuntimeHealth: "執行環境健康狀態",
            .modelRecheck: "重新檢查",
            .modelDownloadSource: "模型下載源",
            .modelCustomEndpointPlaceholder: "自訂 HF_ENDPOINT，可留空使用官方源",
            .modelCurrentSourceOfficial: "目前下載源：Hugging Face 官方源",
            .modelCurrentSourceFormat: "目前下載源：%@",
            .modelLiteBundleTitle: "Lite 包：0.6B CustomVoice + Base",
            .modelLiteBundleNote: "預覽和基礎機型優先；CustomVoice 用於精品生成，Base 用於克隆生成和對話生成。",
            .modelProBundleTitle: "Pro 包：1.7B CustomVoice + Base",
            .modelProBundleNote: "正式匯出品質優先；CustomVoice 控制力更強，Base 克隆品質更高。",
            .modelDesignBundleTitle: "Design 包：1.7B VoiceDesign",
            .modelDesignBundleNote: "自然語言聲音創造；滿意後保存為可復用角色音色。",
            .modelInstalled: "已安裝",
            .modelDownload: "下載",
            .modelUseDefaultPath: "使用預設路徑",
            .modelChooseLocalPath: "選擇本機路徑",
            .modelPrecisionTitle: "VoiceDesign 精度/版本",
            .modelCurrentValueFormat: "目前：%@",
            .modelUseThisVersion: "使用此版本",
            .modelUsingThisVersion: "正在使用",
            .modelMissing: "未安裝",
            .modelReady: "已安裝",
            .runtimeInstallFirstUse: "首次在新 Mac 上使用時，需要先安裝本機執行環境：Python 3.12、MLX、mlx-audio、transformers、Hugging Face CLI 和 ffmpeg。",
            .runtimeInstallAudioToolWarning: "目前 MLX 推理已可用，但 ffmpeg 缺失。請先安裝 Homebrew，再執行 brew install python@3.12 ffmpeg，或使用安裝/修復。",
            .runtimeInstallDownloadToolWarning: "目前缺少 Hugging Face CLI 命令 hf，模型下載會失敗。安裝/修復會執行 pip install -U \"huggingface_hub[cli]\" hf_transfer，並把 hf 加入 Voice Studio runtime PATH。",
            .runtimeInstallSSLHint: "如果日誌出現 LibreSSL / urllib3 / SSL 相關提示，通常是系統 Python 過舊；安裝器會優先使用 Homebrew python@3.12。",
            .runtimeInstallInstalling: "正在安裝執行環境",
            .runtimeInstallRepair: "安裝/修復執行環境",
            .runtimeInstallProgress: "安裝進度",
            .runtimeInstallWaitingOutput: "等待安裝輸出...",
            .runtimeInstallFullLog: "查看完整安裝日誌",
            .runtimeOptionalExtensions: "可選擴充",
            .runtimeInstallNotStarted: "未開始",
            .runtimeInstallPreparing: "準備安裝",
            .runtimeInstallCompleted: "安裝完成",
            .runtimeInstallFailed: "安裝失敗",
            .runtimeInstallMissingScriptStatus: "找不到執行環境安裝腳本",
            .runtimeInstallMissingScriptLog: "找不到 scripts/install_runtime.sh。請重新下載新版 Voice Studio。",
            .runtimeStatusRealInference: "真實推理",
            .runtimeStatusModelNotReady: "模型未就緒",
            .runtimeStatusUnavailable: "執行環境不可用",
            .runtimeStatusDownloadToolMissing: "下載工具缺失",
            .runtimeStatusAudioToolMissing: "音訊工具缺失",
            .runtimeStatusNeedsRepair: "執行環境需修復",
            .statusReady: "準備就緒",
            .statusRuntimeUnknown: "執行環境狀態無法識別",
            .statusRuntimeCheckFailedFormat: "執行環境檢查失敗：%@",
            .commonClear: "清空",
            .commonPlay: "播放",
            .commonPause: "暫停",
            .commonExport: "匯出",
            .commonDelete: "刪除",
            .commonCancel: "取消",
            .commonSave: "保存",
            .commonOpenSettings: "打開設定",
            .commonAddAudio: "添加音訊",
            .commonOutputFileName: "輸出檔名",
            .commonPreview: "試聽",
            .commonMoveUp: "上移",
            .commonMoveDown: "下移",
            .commonJumpTo: "跳到",
            .commonPageNumber: "頁碼",
            .commonJump: "跳轉",
            .commonConfigured: "已配置",
            .commonNotConfigured: "未配置",
            .commonOfficialSource: "官方源",
            .commonHFMirror: "HF Mirror",
            .commonMissing: "缺失",
            .commonClearSelection: "清空",
            .scriptWorkflow: "工作流",
            .scriptGenerationModel: "生成模型",
            .scriptVoice: "音色",
            .scriptNoReusableVoice: "暫無可復用音色",
            .scriptSelectReusableVoice: "選擇可復用音色",
            .scriptRecordedClonedVoices: "錄製/導入克隆音色",
            .scriptDesignedVoices: "VoiceDesign 創造音色",
            .scriptModelInputTitle: "模型輸入",
            .scriptVoiceInput: "語音輸入",
            .scriptStopVoiceInput: "停止語音輸入",
            .scriptVoiceInputHelp: "呼叫 macOS 系統語音識別，把麥克風輸入寫入待生成文字。",
            .scriptMissingFormat: "缺失：%@",
            .scriptVoiceControlTitle: "聲音控制",
            .scriptVoiceControlSubtitle: "選擇或編輯控制屬性後，點擊應用到指令控制。",
            .scriptExpand: "展開",
            .scriptCollapse: "收起",
            .scriptBoundReferenceAudio: "已綁定參考音訊",
            .scriptReferenceTranscript: "參考逐字稿",
            .scriptReferenceTranscriptNote: "Base 固定復用保存音色時綁定的 reference transcript，避免參考音訊和逐字稿錯配。",
            .scriptRoleVoiceBindingTitle: "角色音色綁定",
            .scriptRoleVoiceBindingSubtitle: "每個角色必須綁定一個已保存的克隆音色或創造音色；Base 逐句復用 ref_audio/ref_text。",
            .scriptRoleVoiceRoute: "角色音色 + Base",
            .scriptRoleVoiceEmptyHint: "在合成文本裡寫「角色名: 台詞」。系統會解析角色列表；每個角色都需要在這裡綁定已保存音色。",
            .scriptDesignedVoicePool: "創造音色池",
            .scriptNoDesignedVoiceHint: "暫無創造音色。先在左側「創造音色」保存角色聲音，再回到這裡選擇使用。",
            .scriptMissingRefText: "缺少 ref_text",
            .scriptUnboundVoice: "未綁定音色",
            .scriptRefTextFormat: "ref_text：%@",
            .scriptBindVoice: "綁定音色",
            .scriptUnbound: "未綁定",
            .scriptSelectedDesignedVoices: "已選創造音色",
            .scriptOtherDesignedVoices: "其他創造音色",
            .scriptGenerationControlTitle: "指令控制",
            .scriptSynthesisText: "合成文本",
            .scriptGenerationControlPlaceholder: "未設定控制指令；將使用所選音色的預設風格。",
            .scriptFinalControlInstruction: "最終送入模型的控制指令",
            .scriptRandomGenerate: "隨機生成",
            .scriptRestoreDefaultInstruction: "恢復預設指令",
            .scriptCloneNoInstructionTitle: "克隆生成不使用指令控制",
            .scriptCloneNoInstructionSubtitle: "音色來自 RefAudio 和 RefText；生成時會復用所選音色綁定的參考音訊和參考逐字稿，不再額外傳入控制指令。",
            .scriptGenerateFullText: "生成全文",
            .scriptCancelQueue: "取消佇列",
            .scriptExportFullText: "匯出全文",
            .scriptMerging: "合成中",
            .scriptMergedFullWebM: "已合併完整 WebM",
            .scriptMultiRoleSynthesisHint: "用「角色名: 台詞」寫對話；生成時會去掉角色標籤，按綁定音色逐句 Base 合成並合併為完整 WebM。",
            .scriptDefaultSynthesisHintFormat: "內部會拆成 %@ 個生成段；生成全文後會合併為完整 WebM",
            .scriptModelInputSubtitleMultiRole: "對話生成：只使用已綁定角色音色，Base 逐句合成後合併為完整 WebM。",
            .scriptModelInputSubtitleRoleWarning: "偵測到多角色腳本：請切換到「對話生成」以避免角色聲線漂移。",
            .scriptModelInputSubtitleBuiltin: "CustomVoice：確認 language，編輯指令控制，音色由上方選擇。",
            .scriptModelInputSubtitleCustom: "Base Clone：確認 language，並使用可復用音色綁定的參考組。",
            .scriptModelInputSubtitleVoiceDesign: "VoiceDesign：確認 language，編輯聲音設計指令。",
            .scriptRouteMultiRole: "對話生成：角色音色 + Base 逐句復用並合併",
            .scriptRouteRoleWarning: "偵測到角色腳本：請切換到對話生成",
            .scriptRouteBuiltin: "CustomVoice：精品 speaker 與風格控制",
            .scriptRouteCustom: "Base Clone：復用克隆音色或創造音色",
            .scriptRouteVoiceDesign: "VoiceDesign：用自然語言描述直接創造聲音",
            .scriptApplyToInstruction: "應用到指令控制",
            .scriptSupplementalVoiceIdentity: "補充聲音身分描述",
            .scriptSupplementalPerformance: "補充演繹指令",
            .scriptChooseAttributeFormat: "選擇%@",
            .scriptNotSpecified: "不指定",
            .voiceToolsMergeTitle: "依序合併音訊",
            .voiceToolsMergeSubtitle: "選擇多個音訊後按列表順序合併；支援 wav、mp3、m4a、aac、flac、ogg、opus、aiff、caf、webm，副檔名大小寫不敏感。",
            .voiceToolsMergeButton: "合併為總音訊",
            .voiceToolsMerging: "合併中",
            .voiceToolsEmptyTitle: "還沒有待合併音訊",
            .voiceToolsEmptySubtitle: "點擊「添加音訊」選擇一組檔案；如果順序不對，可以在列表中用上移/下移調整。",
            .voiceToolsRemove: "移除",
            .voiceToolsResultTitle: "合併結果",
            .voiceToolsResultSubtitle: "生成後的總音訊會保存在目前 workspace 的 outputs 目錄。",
            .voiceToolsPlayMerged: "播放總音訊",
            .voiceToolsPauseMerged: "暫停總音訊",
            .voiceToolsResultEmpty: "合併完成後會顯示總音訊路徑，並提供播放和匯出。",
            .cloneDeleteTitle: "刪除克隆音色？",
            .cloneDeleteRecordOnly: "僅刪除音色記錄",
            .cloneDeleteRecordAndFiles: "刪除記錄並刪除關聯檔案",
            .cloneDeleteMessage: "刪除檔案只會處理 Voice Studio workspace 內的參考音訊和 clone prompt。",
            .cloneCountFormat: "%@ 個克隆音色",
            .cloneTranscriptTitle: "1. 參考逐字稿",
            .cloneTranscriptSubtitle: "直接編輯這段文字；錄音內容盡量逐字匹配。",
            .cloneTranscriptPlaceholder: "請讓錄音內容逐字匹配這裡的文本",
            .cloneFillFromScript: "用目前旁白填入",
            .cloneTranscriptExamplesTitle: "參考逐字稿範例",
            .cloneTranscriptExamplesSubtitle: "可選。點擊候選句會替換第 1 步文本。",
            .cloneTranscriptExampleApplied: "已填入參考逐字稿範例",
            .cloneExamplesCountFormat: "%@ 條",
            .cloneReferenceAudioTitle: "2. 參考音訊",
            .cloneReferenceAudioSubtitle: "導入或錄製後先試聽，確認逐字稿匹配後保存為克隆音色。",
            .cloneImportAudio: "導入音訊",
            .cloneRecordAudio: "錄製參考音訊",
            .cloneStopRecording: "停止錄音",
            .clonePlayReference: "播放參考音訊",
            .clonePauseReference: "暫停參考音訊",
            .cloneDeleteReferenceAudio: "刪除目前參考音訊",
            .cloneSaveAsVoice: "保存為克隆音色",
            .cloneCanSave: "可保存",
            .cloneMissingFormat: "還缺：%@",
            .cloneReferenceAudioPath: "參考音訊路徑",
            .cloneReferenceAudioMissing: "未錄入參考音訊",
            .cloneReferenceAudioReady: "參考音訊已錄入",
            .cloneDurationFormat: "時長：%@",
            .cloneSavedTitle: "已保存克隆音色",
            .cloneSavedSubtitle: "管理、重命名、刪除或發送到 Voice Studio 使用。",
            .cloneEmptySaved: "還沒有克隆音色。完成左側參考逐字稿和參考音訊後會顯示在這裡。",
            .cloneMissingRecordedAudio: "未記錄參考音訊",
            .cloneUseForGeneration: "用於生成",
            .cloneGenerateTestSentence: "生成測試句",
            .cloneRename: "重命名",
            .cloneSaveSheetSubtitle: "這裡的名稱會寫入已保存克隆音色列表，並綁定目前參考聲音與逐字稿。",
            .cloneVoiceNamePlaceholder: "克隆音色名稱",
            .clonePurposePlaceholder: "授權用途說明",
            .cloneCanSaveSheet: "可保存為克隆音色",
            .cloneRenameTitle: "重命名克隆音色",
            .cloneRenamePlaceholder: "新的音色名稱",
            .cloneReferenceAudioRequirement: "參考音訊",
            .cloneReferenceTranscriptRequirement: "參考逐字稿",
            .cloneVoiceNameRequirement: "音色名稱",
            .clonePurposeRequirement: "授權用途",
            .designDeleteTitle: "刪除創造音色？",
            .designLanguage: "語言",
            .designInstructionTitle: "指令控制",
            .designInstructionSubtitle: "直接作為 VoiceDesign 的 instruct/prompt 送入模型。",
            .designSynthesisTitle: "合成文本 / 試聽文本",
            .designSynthesisSubtitle: "模型要朗讀的正文內容；保存角色音色時會作為這次參考聲音的文本。",
            .designGenerating: "生成中",
            .designGenerateReferenceVoice: "生成參考聲音",
            .designPlayReferenceVoice: "播放參考聲音",
            .designPauseReferenceVoice: "暫停參考聲音",
            .designSaveAsVoice: "保存為音色",
            .designEnhanceControlTitle: "增強控制指令",
            .designEnhanceControlSubtitle: "控制類型和 DeepSeek 都只生成候選指令；點擊應用後才會寫回上方指令控制。",
            .designControlTypeSubtitle: "展開後可選擇並編輯 VoiceDesign 控制屬性。",
            .designGenerateInitialInstruction: "生成初始控制指令",
            .designApplyInitialInstruction: "應用初始指令",
            .designInitialInstructionTitle: "初始控制指令",
            .designInitialInstructionSubtitle: "由控制類型組合生成，可手動編輯；不會自動影響上方主輸入。",
            .designEnhancing: "增強中",
            .designUseDeepSeekEnhance: "使用 DeepSeek 增強",
            .designApplyEnhancedInstruction: "應用增強指令",
            .designDeepSeekInstructionTitle: "DeepSeek 增強指令",
            .designDeepSeekInstructionSubtitle: "DeepSeek 的聯網增強輸出會顯示在這裡，確認後再應用到上方指令控制。",
            .designDeepSeekConfiguredHint: "可使用聯網增強生成候選控制指令。",
            .designDeepSeekMissingHint: "在「設定」裡配置 API key 後可使用聯網增強。",
            .designGenerationProgress: "生成進度",
            .designSavedTitle: "已保存創造音色",
            .designSavedSubtitle: "管理、重命名、刪除或發送到 Voice Studio 使用。",
            .designEmptySaved: "還沒有保存的創造音色。生成參考聲音並保存後會顯示在這裡。",
            .designPreviewReference: "試聽參考音",
            .designPausePreviewReference: "暫停參考音",
            .designSaveRoleTitle: "保存為角色音色",
            .designSaveRoleSubtitle: "這裡的名稱會寫入已保存創造音色列表，並綁定目前參考聲音與試聽文本。",
            .designSaveNamePlaceholder: "輸入要保存的音色名稱",
            .designRenameTitle: "重命名創造音色",
            .designStatusAppliedInitial: "已將初始控制指令應用到上方主輸入",
            .designStatusAppliedEnhanced: "已將 DeepSeek 增強指令應用到上方主輸入",
            .designStatusNeedInstruction: "請先填寫上方指令控制，或生成初始控制指令",
            .designDeepSeekPurpose: "VoiceDesign 聲音創造",
            .designDeepSeekControlType: "VoiceDesign 控制指令增強",
            .designNameEmpty: "音色名稱不能為空",
            .designNameDuplicate: "音色名稱已存在，請換一個名稱再保存。",
            .rewriteSourceTitle: "原始文本",
            .rewriteSourceSubtitle: "貼上目前要改寫的小說片段；長篇內容建議分段處理。",
            .rewriteControlTitle: "改寫控制",
            .rewriteControlSubtitle: "這些提示只影響 DeepSeek 改寫，不會直接送入 TTS 模型。",
            .rewriteContextPlaceholder: "上文摘要，可留空",
            .rewriteStylePlaceholder: "角色 / 風格提示，例如：科幻、克制、沉浸式；旁白沉穩，人物台詞壓抑",
            .rewriteDeepSeekConfiguredHint: "可聯網生成對話腳本候選。",
            .rewriteDeepSeekMissingHint: "在「設定」裡配置 API key 後可使用對話改寫。",
            .rewriteResultTitle: "生成結果預覽",
            .rewriteResultSubtitle: "確認後再應用到 Script Studio；應用時會自動切換到「對話生成」。",
            .rewriteApplyToScriptStudio: "應用到 Script Studio",
            .rewriteRolePreviewTitle: "角色提示預覽",
            .rewriteRolePreviewSubtitle: "用於後續在對話生成中綁定或創建角色音色。",
            .rewriteNoRoles: "暫未識別到角色。",
            .rewriteNoVoiceHint: "未提供聲音建議",
            .rewriteEmptyHint: "生成後會顯示 DeepSeek 返回的角色和聲音建議。",
            .workspaceInitializing: "初始化中",
            .workspaceNotInitialized: "Workspace 未初始化",
            .workspaceUseDefault: "使用預設 Workspace",
            .workspaceOpenLocation: "打開位置",
            .premiumSpeakerCountFormat: "%@ 個 speaker",
            .premiumTemplateNatural: "自然旁白",
            .premiumTemplateNaturalInstruction: "自然、清晰、穩定，適合長時間旁白。",
            .premiumTemplateEmotional: "情緒更強",
            .premiumTemplateEmotionalInstruction: "情緒更飽滿，語氣有感染力，但保持吐字清楚。",
            .premiumTemplateSlowClear: "慢速清晰",
            .premiumTemplateSlowClearInstruction: "語速偏慢，停頓自然，重點詞更清晰。",
            .premiumTemplateCharacter: "角色化",
            .premiumTemplateCharacterInstruction: "帶有明確 persona，語氣更有角色感和畫面感。"
        ]

        let copied: [AppLanguage: [AppLocalizationKey: String]] = [
            .japanese: localizedCopy(
                base: english,
                settings: ("設定", "インターフェース言語", "モデル", "ダウンロード", "準備完了"),
                workspace: ("プレミアム音色", "クローン音色", "音色作成", "テキスト堅牢性", "会話リライト")
            ),
            .korean: localizedCopy(
                base: english,
                settings: ("설정", "인터페이스 언어", "모델", "다운로드", "준비됨"),
                workspace: ("프리미엄 보이스", "복제 보이스", "보이스 디자인", "텍스트 견고성", "대화 다시 쓰기")
            ),
            .german: localizedCopy(
                base: english,
                settings: ("Einstellungen", "Oberflächensprache", "Modelle", "Herunterladen", "Bereit"),
                workspace: ("Premium-Stimmen", "Klonstimmen", "Stimme erstellen", "Textrobustheit", "Dialog umschreiben")
            ),
            .french: localizedCopy(
                base: english,
                settings: ("Paramètres", "Langue de l’interface", "Modèles", "Télécharger", "Prêt"),
                workspace: ("Voix premium", "Voix clonées", "Créer une voix", "Robustesse du texte", "Réécriture du dialogue")
            ),
            .russian: localizedCopy(
                base: english,
                settings: ("Настройки", "Язык интерфейса", "Модели", "Скачать", "Готово"),
                workspace: ("Премиум голоса", "Клонированные голоса", "Создать голос", "Устойчивость текста", "Переписать диалог")
            ),
            .portuguese: localizedCopy(
                base: english,
                settings: ("Configurações", "Idioma da interface", "Modelos", "Baixar", "Pronto"),
                workspace: ("Vozes premium", "Vozes clonadas", "Criar voz", "Robustez de texto", "Reescrever diálogo")
            ),
            .spanish: localizedCopy(
                base: english,
                settings: ("Ajustes", "Idioma de la interfaz", "Modelos", "Descargar", "Listo"),
                workspace: ("Voces premium", "Voces clonadas", "Crear voz", "Robustez de texto", "Reescribir diálogo")
            ),
            .italian: localizedCopy(
                base: english,
                settings: ("Impostazioni", "Lingua interfaccia", "Modelli", "Scarica", "Pronto"),
                workspace: ("Voci premium", "Voci clonate", "Crea voce", "Robustezza testo", "Riscrittura dialogo")
            )
        ]
        for (language, values) in copied {
            table[language] = values
        }
        return table
    }()

    private static func localizedCopy(
        base: [AppLocalizationKey: String],
        settings: (title: String, language: String, models: String, download: String, ready: String),
        workspace: (premium: String, cloned: String, design: String, robustness: String, rewrite: String)
    ) -> [AppLocalizationKey: String] {
        var values = base
        values[.settingsTitle] = settings.title
        values[.workspaceSettings] = settings.title
        values[.settingsInterfaceLanguageTitle] = settings.language
        values[.workspaceModels] = settings.models
        values[.modelDownload] = settings.download
        values[.modelReady] = settings.ready
        values[.workspacePremiumVoices] = workspace.premium
        values[.workspaceClonedVoices] = workspace.cloned
        values[.workspaceVoiceDesign] = workspace.design
        values[.workspaceTextRobustness] = workspace.robustness
        values[.workspaceScriptRewrite] = workspace.rewrite
        return values
    }
}
