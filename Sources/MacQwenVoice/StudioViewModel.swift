import AppKit
import AVFoundation
import Foundation
import MacQwenVoiceCore
import Speech
import UniformTypeIdentifiers

enum MultiRoleVoicePreparationStatus: Equatable {
    case missing
    case generating
    case ready
    case failed(String)

    var title: String {
        switch self {
        case .missing:
            "未绑定"
        case .generating:
            "生成中"
        case .ready:
            "已就绪"
        case .failed:
            "失败"
        }
    }
}

enum MultiRoleVoiceSourceKind: Equatable {
    case unbound
    case clonedVoice
    case voiceDesign
    case generatedFromPrompt

    var title: String {
        switch self {
        case .unbound:
            "未绑定"
        case .clonedVoice:
            "克隆音色"
        case .voiceDesign:
            "创造音色"
        case .generatedFromPrompt:
            "创造音色"
        }
    }
}

struct MultiRoleVoicePreparationItem: Identifiable, Equatable {
    var speaker: String
    var instruction: String
    var referenceText: String
    var boundVoiceID: String?
    var boundVoiceName: String?
    var sourceKind: MultiRoleVoiceSourceKind
    var status: MultiRoleVoicePreparationStatus
    var referenceAudioPath: String?
    var boundReferenceText: String?
    var missingRequirements: [String]

    var id: String { speaker }
    var roleName: String { speaker }
}

struct VoiceToolsAudioMergeItem: Identifiable, Equatable {
    let id: String
    var fileName: String
    var originalPath: String
    var workspacePath: String

    init(id: String = UUID().uuidString, fileName: String, originalPath: String, workspacePath: String) {
        self.id = id
        self.fileName = fileName
        self.originalPath = originalPath
        self.workspacePath = workspacePath
    }
}

@MainActor
final class StudioViewModel: ObservableObject {
    @Published var text: String = "其实我真的有发现，我是一个特别善于观察别人情绪的人。"
    @Published var projectTitle: String = VoiceStudioDefaults.defaultProjectTitle
    @Published var selectedModelID: String = ModelCatalog.default.liteBundle.first?.id ?? ""
    @Published var selectedVoiceID: String?
    @Published var selectedVoiceSource: VoiceSourceSelection = .builtin
    @Published var selectedWorkflow: ScriptStudioWorkflow = .builtin
    @Published var scriptStudioLanguageChoice: ScriptStudioLanguageChoice = .automatic
    @Published var instruct: String = VoiceStudioDefaults.defaultBuiltinControlInstruction
    @Published var voiceIdentityDescription: String = VoiceStudioDefaults.defaultVoiceDesignControlInstruction
    @Published var scriptStudioPageDraft = ScriptStudioPageDraft()
    @Published var voiceDesignPageDraft = VoiceDesignPageDraft()
    @Published var scriptRewritePageDraft = ScriptRewritePageDraft()
    @Published var voiceToolsPageDraft = VoiceToolsPageDraft()
    @Published var clonedVoicesPageDraft = ClonedVoicesPageDraft()
    @Published var editedDeliveryStylePrompt: String?
    @Published var editedVoiceIdentityDescription: String?
    @Published var voiceControlProfile: VoiceControlProfile = .defaultNarration
    @Published var statusMessage: String = "准备就绪"
    @Published var segments: [TextSegment] = []
    @Published var voices: [VoiceProfile] = []
    @Published var voiceAssets: [VoiceAsset] = []
    @Published var modelStates: [String: ModelState] = [:]
    @Published var generatedAudioPaths: [String: String] = [:]
    @Published var generatedModelIDs: [String: String] = [:]
    @Published var generatedVoiceNames: [String: String] = [:]
    @Published var generatedInstructions: [String: String] = [:]
    @Published var generatedRuntimes: [String: String] = [:]
    @Published var generationErrors: [String: String] = [:]
    @Published var generatingSegmentIDs: Set<String> = []
    @Published var playingSegmentID: String?
    @Published var playingGenerationID: String?
    @Published var playingAudioItemID: String?
    @Published var isPlayingAllGenerated: Bool = false
    @Published var audioPlaybackProgress: [String: Double] = [:]
    @Published var audioPlaybackDuration: [String: Double] = [:]
    @Published var isGeneratingAllSegments: Bool = false
    @Published var generationProgress: [String: Double] = [:]
    @Published var generationProgressLabel: [String: String] = [:]
    @Published var generationHistory: [GenerationRecord] = []
    @Published var fullGeneratedAudioPath: String?
    @Published var isMergingFullGeneratedAudio: Bool = false
    @Published var downloadLogs: [String: String] = [:]
    @Published var huggingFaceEndpoint: String = HuggingFaceEndpointPreference.load() {
        didSet {
            HuggingFaceEndpointPreference.save(huggingFaceEndpoint)
        }
    }
    @Published var runtimeHealth: RuntimeHealthViewState = .unknown
    @Published var isInstallingRuntime: Bool = false
    @Published var runtimeInstallLog: String = ""
    @Published var runtimeInstallProgress: Double = 0
    @Published var runtimeInstallPhase: String = "未开始"
    @Published var cloneReferenceAudioPath: String = ""
    @Published var cloneReferenceText: String = VoiceStudioDefaults.cloneReferenceTranscript
    @Published var clonePurpose: String = "本人声音或已获授权，用于本地旁白生成"
    @Published var cloneReferenceDuration: Double?
    @Published var isRecordingReference: Bool = false
    @Published var isDictatingText: Bool = false
    @Published var isInitializingWorkspace: Bool = false
    @Published var workspaceReady: Bool = false
    @Published var voiceDesignPreviewPath: String?
    @Published var isGeneratingVoiceDesign: Bool = false
    @Published var voiceDesignProgress: Double = 0
    @Published var voiceDesignProgressLabel: String = "准备生成"
    @Published var deepSeekAPIKeyInput: String = ""
    @Published var isDeepSeekConfigured: Bool = false
    @Published var isEnhancingVoiceDescription: Bool = false
    @Published var isRewritingScriptWithDeepSeek: Bool = false
    @Published var scriptStudioReferenceTextOverride: String = ""
    @Published var multiRoleVoicePreparationStatus: [String: MultiRoleVoicePreparationStatus] = [:]
    @Published var multiRoleVoiceBindings: [String: String] = [:]
    @Published var multiRoleSelectedDesignedVoiceIDs: Set<String> = []
    @Published var voiceToolsAudioMergeItems: [VoiceToolsAudioMergeItem] = []
    @Published var voiceToolsMergedAudioPath: String?
    @Published var isMergingVoiceToolsAudio: Bool = false
    @Published var voiceToolsStatusMessage: String = "选择两个或更多音频后即可按顺序合并"

    let catalog = ModelCatalog.default
    @Published var paths: AppPaths
    private let segmenter = TextSegmenter(maxCharacters: 420)
    private let maxSegmentCharacters = 420
    private var database: AppDatabase?
    private var backend: BackendJSONClient
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var currentRecordingURL: URL?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
    private var speechAudioEngine = AVAudioEngine()
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private var dictationBaseText: String = ""
    private var isSpeechTapInstalled = false
    private var progressTasks: [String: Task<Void, Never>] = [:]
    private var voiceDesignProgressTask: Task<Void, Never>?
    private var playbackProgressTask: Task<Void, Never>?
    private var playAllGeneratedTask: Task<Void, Never>?
    private var currentPlaybackPath: String?
    private var currentPlaybackAudioID: String?
    private var pausedPlaybackPoint: PlaybackResumePoint?
    private var playAllQueuePaths: [String] = []
    private var playAllCurrentIndex: Int?
    private var pausedPlayAllState: PlaybackQueueResumeState?
    private var generationQueueTask: Task<Void, Never>?
    private var roleInstructionBySegmentID: [String: String] = [:]
    private var roleSpeakerBySegmentID: [String: String] = [:]
    private var roleControlInstruction: String = ""
    private let reusableRoleVoiceNamePrefix = "角色 · "
    private var didStartWorkspaceInitialization = false
    private static let userAudioExtension = "webm"
    private static let userAudioContentType = UTType(filenameExtension: "webm") ?? .audio
    private var audioFileDurationCache: [String: Double] = [:]
    private var deepSeekConfigStore: DeepSeekAPIKeyConfigStore
    private var builtinInstructionDraftState = VoiceInstructionDraftState()
    private var voiceDesignInstructionDraftState = VoiceInstructionDraftState()
    private static let multiRoleConcatGapSeconds: Double = 0.65

    init() {
        let initialPaths = AppPaths(root: WorkspaceRootPreference.load())
        paths = initialPaths
        backend = BackendJSONClient(dataDirectory: initialPaths.root)
        deepSeekConfigStore = DeepSeekAPIKeyConfigStore(fileURL: initialPaths.deepSeekConfig)
        voices = Self.previewBuiltinVoices()
        selectedVoiceID = voices.first?.id
        selectedVoiceSource = VoiceSourceSelection.source(for: voices.first)
        let rawWorkflow = ProcessInfo.processInfo.environment["MACQWENVOICE_INITIAL_WORKFLOW"] ?? ""
        selectedWorkflow = ScriptStudioWorkflow(rawValue: rawWorkflow) ?? .builtin
        initializeBuiltinInstructionIfNeeded()
        isDeepSeekConfigured = DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: try? deepSeekConfigStore.read())
        updateSegments()
        statusMessage = WorkspaceStartupPolicy.initialStatusMessage
        initializeWorkspaceIfNeeded()
    }

    func initializeWorkspaceIfNeeded() {
        guard !workspaceReady, !isInitializingWorkspace, !didStartWorkspaceInitialization else { return }
        isInitializingWorkspace = true
        statusMessage = WorkspaceStartupPolicy.initialStatusMessage
        Task { [weak self] in
            await self?.initializeWorkspace()
        }
    }

    private func initializeWorkspace() async {
        guard !didStartWorkspaceInitialization else { return }
        didStartWorkspaceInitialization = true
        do {
            let paths = self.paths
            let shouldMigrateLegacy = WorkspaceRootPreference.isDefaultRoot(paths.root)
            let migrationAndDatabase = try await Task.detached(priority: .userInitiated) {
                let documentsMigration = shouldMigrateLegacy
                    ? try WorkspaceMigrator.relocateWorkspaceIfNeeded(
                        from: AppPaths.legacyDocumentsWorkspaceRoots(),
                        to: paths.root
                    )
                    : WorkspaceMigrationResult(didMigrate: false, migratedItems: [])
                let supportMigration = shouldMigrateLegacy
                    ? try WorkspaceMigrator.migrateIfNeeded(
                        from: AppPaths.legacyApplicationSupportRoot(),
                        to: paths.root
                    )
                    : WorkspaceMigrationResult(didMigrate: false, migratedItems: [])
                let migration = WorkspaceMigrationResult(
                    didMigrate: documentsMigration.didMigrate || supportMigration.didMigrate,
                    migratedItems: Array(Set(documentsMigration.migratedItems + supportMigration.migratedItems)).sorted()
                )
                try paths.ensureDirectories()
                _ = try? SpeechTokenizerStore.normalize(in: paths.models)
                let database = try AppDatabase(path: paths.database.path)
                return (migration, database)
            }.value
            database = migrationAndDatabase.1
            try seedBuiltinVoices()
            try refresh()
            if migrationAndDatabase.0.didMigrate {
                statusMessage = "已迁移旧工作区：\(migrationAndDatabase.0.migratedItems.joined(separator: "、"))"
            } else {
                statusMessage = "准备就绪"
            }
            workspaceReady = true
        } catch {
            statusMessage = "初始化失败：\(error.localizedDescription)"
            didStartWorkspaceInitialization = false
        }
        isInitializingWorkspace = false
        if workspaceReady {
            refreshRuntimeHealth()
            refreshGenerationHistory()
        }
    }

    var defaultWorkspacePath: String {
        AppPaths.defaultRoot().path
    }

    var usesDefaultWorkspace: Bool {
        WorkspaceRootPreference.isDefaultRoot(paths.root)
    }

    func chooseWorkspaceDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "使用此 Workspace"
        panel.message = "选择 Voice Studio 的工作目录；模型、项目、输出音频和数据库会放在这个目录下。"
        panel.directoryURL = paths.root
        if panel.runModal() == .OK, let url = panel.url {
            switchWorkspace(to: url, persistAsCustom: !WorkspaceRootPreference.isDefaultRoot(url))
        }
    }

    func resetToDefaultWorkspace() {
        switchWorkspace(to: AppPaths.defaultRoot(), persistAsCustom: false)
    }

    private func switchWorkspace(to root: URL, persistAsCustom: Bool) {
        guard !isInitializingWorkspace else {
            statusMessage = "Workspace 正在初始化，稍后再切换"
            return
        }
        let standardizedRoot = root.standardizedFileURL
        if standardizedRoot.path == paths.root.standardizedFileURL.path {
            statusMessage = "当前已经使用这个 workspace"
            return
        }
        if persistAsCustom {
            WorkspaceRootPreference.save(standardizedRoot)
        } else {
            WorkspaceRootPreference.reset()
        }
        backend.stop()
        stopPlaybackForWorkspaceSwitch()
        generationQueueTask?.cancel()
        voiceDesignProgressTask?.cancel()
        for task in progressTasks.values {
            task.cancel()
        }
        progressTasks = [:]
        paths = AppPaths(root: standardizedRoot)
        backend = BackendJSONClient(dataDirectory: paths.root)
        deepSeekConfigStore = DeepSeekAPIKeyConfigStore(fileURL: paths.deepSeekConfig)
        database = nil
        workspaceReady = false
        didStartWorkspaceInitialization = false
        runtimeHealth = .unknown
        modelStates = [:]
        voiceAssets = []
        generationHistory = []
        generatedAudioPaths = [:]
        generatedModelIDs = [:]
        generatedVoiceNames = [:]
        generatedInstructions = [:]
        generatedRuntimes = [:]
        generationErrors = [:]
        generationProgress = [:]
        generationProgressLabel = [:]
        isGeneratingAllSegments = false
        isMergingFullGeneratedAudio = false
        isGeneratingVoiceDesign = false
        downloadLogs = [:]
        voices = Self.previewBuiltinVoices()
        selectedVoiceID = voices.first?.id
        selectedVoiceSource = .builtin
        selectedWorkflow = .builtin
        isDeepSeekConfigured = DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: try? deepSeekConfigStore.read())
        statusMessage = "已切换 workspace，正在初始化"
        initializeWorkspaceIfNeeded()
    }

    func updateSegments() {
        let script = SpeakerTaggedTextNormalizer.script(from: text)
        let hasRoutedScript = selectedWorkflow == .multiRole
            ? !SpeakerTaggedTextNormalizer.roleNames(from: text).isEmpty
            : script.hasRoleRouting
        roleInstructionBySegmentID = [:]
        roleSpeakerBySegmentID = [:]
        roleControlInstruction = ""
        if hasRoutedScript {
            roleControlInstruction = selectedWorkflow == .multiRole
                ? ""
                : SpeakerTaggedTextNormalizer.roleControlInstruction(from: text)
            var nextSegments: [TextSegment] = []
            let routedSegments = SpeakerTaggedTextNormalizer.synthesisSegments(from: text, maxCharacters: maxSegmentCharacters)
            for routed in routedSegments {
                let segment = TextSegment(index: nextSegments.count, text: routed.text)
                nextSegments.append(segment)
                if let instruction = routed.instruction, !instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    roleInstructionBySegmentID[segment.id] = instruction
                }
                if let speaker = routed.speaker, !speaker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    roleSpeakerBySegmentID[segment.id] = speaker
                }
            }
            segments = nextSegments
            if selectedWorkflow == .multiRole, !catalog.baseModels.contains(where: { $0.id == selectedModelID }) {
                selectedModelID = catalog.preferredModelID(
                    for: .voiceClone,
                    selectedModelID: selectedModelID,
                    readyModelIDs: currentReadyModelIDs
                )
            }
        } else {
            segments = segmenter.segments(from: SpeakerTaggedTextNormalizer.synthesisText(from: text))
        }
        fullGeneratedAudioPath = nil
    }

    private func routedSegment(for segment: TextSegment) -> SpeakerTaggedSynthesisSegment? {
        if let speaker = roleSpeakerBySegmentID[segment.id], !speaker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let instruction = roleInstructionBySegmentID[segment.id]
            return SpeakerTaggedSynthesisSegment(index: segment.index, speaker: speaker, text: segment.text, instruction: instruction)
        }
        let routed = SpeakerTaggedTextNormalizer.synthesisSegments(from: text, maxCharacters: maxSegmentCharacters)
        if let exact = routed.first(where: { $0.index == segment.index && $0.text == segment.text }) {
            return exact
        }
        guard routed.indices.contains(segment.index) else { return nil }
        return routed[segment.index]
    }

    private func roleSpeaker(for segment: TextSegment) -> String? {
        routedSegment(for: segment)?.speaker?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func roleInstruction(for segment: TextSegment) -> String? {
        routedSegment(for: segment)?.instruction?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasRoleRoutedScript: Bool {
        !SpeakerTaggedTextNormalizer.roleNames(from: text).isEmpty
    }

    func saveProject() {
        guard requireWorkspaceReady(action: "保存项目") else { return }
        do {
            _ = try database?.saveProject(title: projectTitle, rawText: text, defaultVoiceID: selectedVoiceID)
            try refresh()
            statusMessage = "项目已保存"
        } catch {
            statusMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    func toggleTextDictation(replaceExisting: Bool = false) {
        if isDictatingText {
            stopTextDictation(status: "语音输入已停止")
        } else {
            startTextDictation(replaceExisting: replaceExisting)
        }
    }

    private func startTextDictation(replaceExisting: Bool) {
        guard ensurePrivacyUsageDescriptions(
            [.speechRecognition, .microphone],
            action: "语音输入"
        ) else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            statusMessage = "语音输入不可用：系统语音识别当前不可用"
            return
        }

        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            requestMicrophoneForDictation(replaceExisting: replaceExisting)
        case .notDetermined:
            statusMessage = "正在请求系统语音识别权限"
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    guard let self else { return }
                    if status == .authorized {
                        self.requestMicrophoneForDictation(replaceExisting: replaceExisting)
                    } else {
                        self.statusMessage = "语音输入不可用：请在系统设置中允许语音识别"
                    }
                }
            }
        case .denied, .restricted:
            statusMessage = "语音输入不可用：请在系统设置中允许语音识别和麦克风"
        @unknown default:
            statusMessage = "语音输入不可用：系统语音识别权限状态未知"
        }
    }

    private func requestMicrophoneForDictation(replaceExisting: Bool) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            beginTextDictationSession(replaceExisting: replaceExisting)
        case .notDetermined:
            statusMessage = "正在请求麦克风权限"
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.beginTextDictationSession(replaceExisting: replaceExisting)
                    } else {
                        self.statusMessage = "语音输入不可用：未授权麦克风"
                    }
                }
            }
        case .denied, .restricted:
            statusMessage = "语音输入不可用：请在系统设置中允许 MacQwenVoice 使用麦克风"
        @unknown default:
            statusMessage = "语音输入不可用：麦克风权限状态未知"
        }
    }

    private func beginTextDictationSession(replaceExisting: Bool) {
        do {
            resetSpeechRecognitionSessionState()
            speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let speechRecognitionRequest else {
                statusMessage = "语音输入启动失败：无法创建识别请求"
                return
            }
            speechRecognitionRequest.shouldReportPartialResults = true
            speechRecognitionRequest.taskHint = .dictation

            dictationBaseText = replaceExisting ? "" : text.trimmingCharacters(in: .whitespacesAndNewlines)
            let inputNode = speechAudioEngine.inputNode
            let format = inputNode.inputFormat(forBus: 0)
            guard format.channelCount > 0, format.sampleRate > 0 else {
                speechRecognitionRequest.endAudio()
                self.speechRecognitionRequest = nil
                statusMessage = "语音输入启动失败：没有检测到可用的麦克风输入格式"
                return
            }
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak speechRecognitionRequest] buffer, _ in
                speechRecognitionRequest?.append(buffer)
            }
            isSpeechTapInstalled = true
            speechAudioEngine.prepare()
            try speechAudioEngine.start()
            isDictatingText = true
            statusMessage = "正在语音输入：识别结果会写入待生成文字"

            speechRecognitionTask = speechRecognizer?.recognitionTask(with: speechRecognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        let transcript = result.bestTranscription.formattedString
                        self.applyDictationTranscript(transcript)
                        if result.isFinal {
                            self.stopTextDictation(status: "语音输入完成")
                        }
                    }
                    if let error {
                        self.stopTextDictation(status: "语音输入失败：\(error.localizedDescription)")
                    }
                }
            }
        } catch {
            stopTextDictation(status: "语音输入启动失败：\(error.localizedDescription)")
        }
    }

    private func resetSpeechRecognitionSessionState() {
        if speechAudioEngine.isRunning {
            speechAudioEngine.stop()
        }
        if isSpeechTapInstalled {
            speechAudioEngine.inputNode.removeTap(onBus: 0)
            isSpeechTapInstalled = false
        }
        speechRecognitionRequest?.endAudio()
        speechRecognitionTask?.cancel()
        speechRecognitionRequest = nil
        speechRecognitionTask = nil
        speechAudioEngine = AVAudioEngine()
    }

    private func applyDictationTranscript(_ transcript: String) {
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if dictationBaseText.isEmpty {
            text = trimmedTranscript
        } else if trimmedTranscript.isEmpty {
            text = dictationBaseText
        } else {
            text = "\(dictationBaseText)\n\(trimmedTranscript)"
        }
        updateSegments()
    }

    private func stopTextDictation(status: String) {
        resetSpeechRecognitionSessionState()
        isDictatingText = false
        statusMessage = status
    }

    func refreshRuntimeHealth() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.mergePersistedModelStatesIntoMemory()
                let modelPaths = Dictionary(uniqueKeysWithValues: self.modelStates.compactMap { key, value in
                    value.localPath.map { (key, $0) }
                })
                let response = try self.backend.oneShot(method: "runtime.health", params: ["model_paths": modelPaths])
                guard let result = response["result"] as? [String: Any] else {
                    self.statusMessage = "运行时状态不可识别"
                    return
                }
                self.runtimeHealth = RuntimeHealthViewState(payload: result)
                self.reconcileReadyModelStates(from: self.runtimeHealth.modelStatuses)
            } catch {
                self.runtimeHealth = .unavailable(message: error.localizedDescription)
                self.statusMessage = "运行时检查失败：\(error.localizedDescription)"
            }
        }
    }

    func refreshGenerationHistory() {
        Task { [weak self] in
            guard let self else { return }
            if let localHistory = try? self.database?.listGenerations() {
                self.setGenerationHistory(localHistory)
                return
            }
            do {
                let response = try self.backend.oneShot(method: "generation.list")
                guard
                    let result = response["result"] as? [String: Any],
                    let rows = result["generations"] as? [[String: Any]]
                else { return }
                self.setGenerationHistory(rows.compactMap(Self.generationRecord(from:)))
            } catch {
                if let localHistory = try? self.database?.listGenerations() {
                    self.setGenerationHistory(localHistory)
                }
            }
        }
    }

    private func setGenerationHistory(_ history: [GenerationRecord]) {
        generationHistory = history
        if let fullGeneratedAudioPath, FileManager.default.fileExists(atPath: fullGeneratedAudioPath) {
            return
        }
        guard let latestFullRecord = history.first(where: { record in
            record.status == .ready
                && (record.mode == "multi_role_full" || record.mode == "full_audio")
                && !record.audioPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return
        }
        let resolvedPath = resolvedAudioURL(latestFullRecord.audioPath).path
        if FileManager.default.fileExists(atPath: resolvedPath) {
            fullGeneratedAudioPath = resolvedPath
        }
    }

    func markModelReady(_ spec: QwenModelSpec) {
        guard requireWorkspaceReady(action: "更新模型路径") else { return }
        let localPath = paths.modelDirectory(for: spec).path
        saveModelPath(spec, localPath: localPath, statusText: "\(spec.displayName) 已使用默认下载路径")
    }

    func chooseVoiceToolsAudioFiles() {
        guard requireWorkspaceReady(action: "选择待合并音频") else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "加入合并列表"
        panel.message = "选择要按顺序合并的音频；支持 wav、mp3、m4a、aac、flac、ogg、opus、aiff、caf、webm，扩展名大小写不敏感，合并时会统一转码。"
        if panel.runModal() == .OK {
            let imported = panel.urls.compactMap { importVoiceToolsAudioFile($0) }
            if imported.isEmpty {
                voiceToolsStatusMessage = "没有加入可用音频"
            } else {
                voiceToolsAudioMergeItems.append(contentsOf: imported)
                voiceToolsMergedAudioPath = nil
                voiceToolsStatusMessage = "已加入 \(imported.count) 个音频"
            }
        }
    }

    func removeVoiceToolsAudioItem(_ item: VoiceToolsAudioMergeItem) {
        voiceToolsAudioMergeItems.removeAll { $0.id == item.id }
        voiceToolsMergedAudioPath = nil
        voiceToolsStatusMessage = "已从合并列表移除 \(item.fileName)"
    }

    func clearVoiceToolsAudioItems() {
        voiceToolsAudioMergeItems.removeAll()
        voiceToolsMergedAudioPath = nil
        voiceToolsStatusMessage = "已清空合并列表"
    }

    func moveVoiceToolsAudioItem(_ item: VoiceToolsAudioMergeItem, by offset: Int) {
        guard
            let sourceIndex = voiceToolsAudioMergeItems.firstIndex(where: { $0.id == item.id })
        else { return }
        let targetIndex = sourceIndex + offset
        guard voiceToolsAudioMergeItems.indices.contains(targetIndex) else { return }
        voiceToolsAudioMergeItems.swapAt(sourceIndex, targetIndex)
        voiceToolsMergedAudioPath = nil
        voiceToolsStatusMessage = "已调整 \(item.fileName) 的合并顺序"
    }

    func mergeVoiceToolsAudioFiles(outputName: String) {
        guard requireWorkspaceReady(action: "合并音频") else { return }
        guard !isMergingVoiceToolsAudio else {
            voiceToolsStatusMessage = "音频正在合并中"
            return
        }
        guard let plan = VoiceToolsAudioMergePlanner.plan(
            paths: voiceToolsAudioMergeItems.map(\.workspacePath),
            outputName: outputName
        ) else {
            voiceToolsStatusMessage = "至少需要两个受支持的音频文件"
            return
        }
        isMergingVoiceToolsAudio = true
        voiceToolsMergedAudioPath = nil
        voiceToolsStatusMessage = "正在合并 \(plan.paths.count) 个音频"
        let backend = backend
        Task.detached { [weak self, backend, plan] in
            do {
                let response = try Self.performAudioConcat(
                    input: FullAudioMergeInput(
                        backend: backend,
                        paths: plan.paths,
                        outputName: plan.outputName,
                        gapSeconds: 0
                    )
                )
                let audioPath = Self.audioPath(fromConcatResponse: response)
                await MainActor.run {
                    guard let self else { return }
                    self.isMergingVoiceToolsAudio = false
                    guard let audioPath else {
                        self.voiceToolsStatusMessage = Self.errorMessage(from: response, fallback: "音频合并失败")
                        return
                    }
                    self.voiceToolsMergedAudioPath = self.resolvedAudioURL(audioPath).path
                    self.voiceToolsStatusMessage = "已合并为 \(plan.outputName)"
                }
            } catch {
                await MainActor.run {
                    self?.isMergingVoiceToolsAudio = false
                    self?.voiceToolsStatusMessage = "音频合并失败：\(error.localizedDescription)"
                }
            }
        }
    }

    func exportVoiceToolsMergedAudio(defaultName: String) {
        guard let voiceToolsMergedAudioPath, FileManager.default.fileExists(atPath: voiceToolsMergedAudioPath) else {
            voiceToolsStatusMessage = "还没有可导出的合并音频"
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.userAudioContentType]
        panel.canCreateDirectories = true
        let trimmedName = defaultName.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = trimmedName.isEmpty ? "voice-tools-merged.webm" : trimmedName
        panel.nameFieldStringValue = Self.webMFileName(from: baseName)
        if panel.runModal() == .OK, let destination = panel.url {
            copyAudioFile(from: URL(fileURLWithPath: voiceToolsMergedAudioPath), to: destination, successMessage: "Voice Tools 合并音频已导出")
            voiceToolsStatusMessage = statusMessage
        }
    }

    private func importVoiceToolsAudioFile(_ sourceURL: URL) -> VoiceToolsAudioMergeItem? {
        let source = sourceURL.standardizedFileURL
        guard VoiceToolsAudioMergePlanner.isSupportedAudioPath(source.path) else {
            voiceToolsStatusMessage = "暂不支持 \(source.lastPathComponent) 的音频格式"
            return nil
        }
        do {
            let directory = paths.cache.appendingPathComponent("voice-tools", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let destination = directory.appendingPathComponent("\(UUID().uuidString)-\(source.lastPathComponent)")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            return VoiceToolsAudioMergeItem(
                fileName: source.lastPathComponent,
                originalPath: source.path,
                workspacePath: destination.path
            )
        } catch {
            voiceToolsStatusMessage = "导入 \(source.lastPathComponent) 失败：\(error.localizedDescription)"
            return nil
        }
    }

    func chooseModelDirectory(for spec: QwenModelSpec) {
        guard requireWorkspaceReady(action: "选择模型路径") else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "使用此模型目录"
        panel.directoryURL = paths.models
        if panel.runModal() == .OK, let url = panel.url {
            saveModelPath(spec, localPath: url.path, statusText: "\(spec.displayName) 已切换到指定路径")
        }
    }

    func currentModelPath(for spec: QwenModelSpec) -> String {
        modelStates[spec.id]?.localPath ?? paths.modelDirectory(for: spec).path
    }

    func isModelPrecisionChoiceReady(_ choice: ModelPrecisionChoice) -> Bool {
        QwenModelDirectoryValidator.isReady(atPath: choice.localPath(in: paths))
    }

    func isModelPrecisionChoiceSelected(_ choice: ModelPrecisionChoice, for spec: QwenModelSpec) -> Bool {
        normalizedPath(currentModelPath(for: spec)) == normalizedPath(choice.localPath(in: paths))
    }

    func activeModelPrecisionTitle(for spec: QwenModelSpec) -> String {
        spec.precisionChoices.first { isModelPrecisionChoiceSelected($0, for: spec) }?.title
            ?? "自定义路径"
    }

    func selectModelPrecisionChoice(_ choice: ModelPrecisionChoice, for spec: QwenModelSpec) {
        let localPath = choice.localPath(in: paths)
        guard QwenModelDirectoryValidator.isReady(atPath: localPath) else {
            statusMessage = "\(choice.title) 未安装或文件不完整：\(localPath)"
            return
        }
        selectedModelID = spec.id
        saveModelPath(spec, localPath: localPath, statusText: "\(spec.displayName) 已切换到 \(choice.title)")
    }

    private func saveModelPath(_ spec: QwenModelSpec, localPath: String, statusText: String) {
        guard requireWorkspaceReady(action: "更新模型路径") else { return }
        do {
            try database?.saveModelState(ModelState(id: spec.id, localPath: localPath, status: .ready, bytes: nil))
            try refresh()
            refreshRuntimeHealth()
            statusMessage = statusText
        } catch {
            statusMessage = "模型状态更新失败：\(error.localizedDescription)"
        }
    }

    private func normalizedPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }

    func downloadCommand(for spec: QwenModelSpec) -> String {
        let localPath = paths.modelDirectory(for: spec).path
        return HuggingFaceDownloadPlan(repository: spec.repository, localPath: localPath, endpoint: huggingFaceEndpoint).shellCommand
    }

    func modelAvailability(for modelID: String) -> ModelAvailabilityViewState {
        let status = runtimeHealth.modelStatuses.first { $0.id == modelID }
        let spec = catalog.models.first { $0.id == modelID }
        let path = status?.localPath
            ?? modelStates[modelID]?.localPath
            ?? spec.map { paths.modelDirectory(for: $0).path }
            ?? ""
        let localReady = modelStates[modelID]?.status == .ready
        let available = status?.exists ?? localReady
        return ModelAvailabilityViewState(
            modelID: modelID,
            available: available,
            path: path,
            label: available ? "模型文件完整" : "模型未下载/文件不完整"
        )
    }

    func downloadModel(_ spec: QwenModelSpec) {
        guard requireWorkspaceReady(action: "下载模型") else { return }
        do {
            let localPath = paths.modelDirectory(for: spec)
            let endpoint = huggingFaceEndpoint
            try FileManager.default.createDirectory(at: localPath, withIntermediateDirectories: true)
            try database?.saveModelState(ModelState(id: spec.id, localPath: localPath.path, status: .downloading, bytes: nil))
            try refresh()
            statusMessage = "开始下载 \(spec.displayName)"

            Task.detached { [weak self, endpoint] in
                let plan = HuggingFaceDownloadPlan(repository: spec.repository, localPath: localPath.path, endpoint: endpoint)
                let result = Self.runDownload(plan: plan)
                await MainActor.run {
                    self?.finishDownload(spec, localPath: localPath.path, result: result)
                }
            }
        } catch {
            statusMessage = "下载启动失败：\(error.localizedDescription)"
        }
    }

    func installRuntimeEnvironment() {
        guard !isInstallingRuntime else { return }
        guard let scriptURL = VoiceStudioRuntimeEnvironment.installScriptURL else {
            statusMessage = "未找到运行环境安装脚本"
            runtimeInstallLog = "未找到 scripts/install_runtime.sh。请重新下载新版 Voice Studio。"
            return
        }

        isInstallingRuntime = true
        runtimeInstallProgress = 0.02
        runtimeInstallPhase = "准备安装"
        runtimeInstallLog = "开始安装运行环境...\n\(scriptURL.path)\n"
        statusMessage = "正在安装运行环境"

        Task.detached { [weak self] in
            let result = await Self.runRuntimeInstaller(scriptURL: scriptURL) { chunk in
                await MainActor.run {
                    self?.appendRuntimeInstallOutput(chunk)
                }
            }
            await MainActor.run {
                guard let self else { return }
                self.isInstallingRuntime = false
                if !result.output.isEmpty, !self.runtimeInstallLog.hasSuffix(result.output) {
                    self.appendRuntimeInstallOutput("\n\(result.output)")
                }
                if result.status == 0 {
                    self.runtimeInstallProgress = 1
                    self.runtimeInstallPhase = "安装完成"
                    self.statusMessage = "运行环境安装完成，正在重新检查"
                    self.backend.stop()
                    self.refreshRuntimeHealth()
                } else {
                    self.runtimeInstallPhase = "安装失败"
                    self.statusMessage = "运行环境安装失败，请查看日志"
                }
            }
        }
    }

    private func appendRuntimeInstallOutput(_ text: String) {
        runtimeInstallLog += text
        for line in text.components(separatedBy: .newlines) {
            if let progress = RuntimeInstallerProgress.parse(line: line) {
                runtimeInstallProgress = progress.fraction
                runtimeInstallPhase = progress.message
            }
        }
        let maxCharacters = 30_000
        if runtimeInstallLog.count > maxCharacters {
            runtimeInstallLog = String(runtimeInstallLog.suffix(maxCharacters))
        }
    }

    func selectVoice(_ voice: VoiceProfile) {
        selectedVoiceID = voice.id
        selectedVoiceSource = VoiceSourceSelection.source(for: voice)
        selectedWorkflow = workflow(for: voice)
        if voice.kind == .customVoice {
            scriptStudioLanguageChoice = BuiltinVoiceDisplayName.defaultLanguageChoice(for: voice)
            applyScriptStudioLanguageChoiceToControlProfile(scriptStudioLanguageChoice)
            initializeBuiltinInstructionIfNeeded()
            if !builtinInstructionDraftState.wasEditedByUser {
                editedDeliveryStylePrompt = nil
            }
        } else {
            applyVoiceLanguageToControlProfile(voice.language)
        }
        if voice.kind != .customVoice, !voice.instruct.isEmpty {
            instruct = voice.instruct
        }
        scriptStudioReferenceTextOverride = ""
        selectedModelID = modelID(for: voice)
        normalizeScriptStudioControlsForSelectedWorkflow()
    }

    func initializeBuiltinInstructionIfNeeded() {
        guard let template = VoiceInstructionLibrary.randomTemplate(for: .customVoice) else { return }
        if builtinInstructionDraftState.initializeIfNeeded(with: template) {
            instruct = builtinInstructionDraftState.value
        } else if builtinInstructionDraftState.wasEditedByUser {
            instruct = builtinInstructionDraftState.value
        } else if instruct.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !builtinInstructionDraftState.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            instruct = builtinInstructionDraftState.value
        }
    }

    func initializeVoiceDesignInstructionIfNeeded() {
        let template = VoiceInstructionTemplate(
            id: "default-voice-design-control",
            title: "默认创造生成",
            workflow: .voiceDesign,
            instruction: VoiceStudioDefaults.defaultVoiceDesignControlInstruction
        )
        if voiceDesignInstructionDraftState.initializeIfNeeded(with: template) {
            voiceIdentityDescription = voiceDesignInstructionDraftState.value
        } else if voiceDesignInstructionDraftState.wasEditedByUser {
            voiceIdentityDescription = voiceDesignInstructionDraftState.value
        }
    }

    func selectVoice(id: String?) {
        guard let id, let voice = voices.first(where: { $0.id == id }) else { return }
        selectVoice(voice)
    }

    func selectVoiceSource(_ source: VoiceSourceSelection) {
        selectedVoiceSource = source
        selectedWorkflow = source == .builtin ? .builtin : .custom
        let candidates = source == .builtin ? builtinVoices : customVoices
        if let selectedVoiceID, candidates.contains(where: { $0.id == selectedVoiceID }) {
            ensureGenerationModelMatchesSelectedVoice()
            normalizeScriptStudioControlsForSelectedWorkflow()
            return
        }
        if let first = candidates.first {
            selectVoice(first)
        } else {
            selectedVoiceID = nil
            normalizeScriptStudioControlsForSelectedWorkflow()
        }
    }

    func ensureGenerationModelMatchesSelectedVoice() {
        guard selectedWorkflow != .voiceDesign, selectedWorkflow != .multiRole else { return }
        guard let selectedVoice else { return }
        selectedModelID = modelID(for: selectedVoice)
    }

    func selectScriptStudioWorkflow(_ workflow: ScriptStudioWorkflow) {
        selectedWorkflow = workflow
        let readyModelIDs = Set(modelStates.values.filter { $0.status == .ready }.map(\.id))
        selectedModelID = catalog.preferredModelID(
            forWorkflow: workflow,
            selectedModelID: selectedModelID,
            readyModelIDs: readyModelIDs
        )
        switch workflow {
        case .builtin:
            selectVoiceSource(.builtin)
            statusMessage = "已切换到精品生成：CustomVoice 使用精品 speaker、language、instruct 和 text"
        case .custom:
            selectVoiceSource(.custom)
            if customVoices.isEmpty {
                statusMessage = "克隆生成需要先在“克隆音色”或“创造音色”保存一个可复用音色"
            } else {
                statusMessage = "已切换到克隆生成：Base 会复用已保存音色的 ref_audio/ref_text"
            }
        case .voiceDesign:
            selectedVoiceSource = .custom
            selectedVoiceID = nil
            initializeVoiceDesignInstructionIfNeeded()
            statusMessage = "已切换到创造生成：VoiceDesign 会使用控制指令直接生成单人声音"
        case .multiRole:
            selectedVoiceSource = .custom
            selectedVoiceID = nil
            statusMessage = "已切换到对话生成：绑定角色音色后用 Base 逐句生成并合并"
        }
        normalizeScriptStudioControlsForSelectedWorkflow()
        updateSegments()
    }

    func selectCloneBaseModel(id: String? = nil) {
        let readyModelIDs = Set(modelStates.values.filter { $0.status == .ready }.map(\.id))
        let nextModelID = catalog.preferredModelID(
            for: .voiceClone,
            selectedModelID: id ?? selectedModelID,
            readyModelIDs: readyModelIDs
        )
        selectedModelID = nextModelID
        if let model = catalog.models.first(where: { $0.id == nextModelID }) {
            statusMessage = "已选择 Base 克隆模型：\(model.displayName)"
        }
    }

    func selectScriptStudioModel(id: String) {
        guard let model = catalog.models.first(where: { $0.id == id }) else { return }
        selectedModelID = id

        switch model.capability {
        case .customVoice:
            selectedWorkflow = .builtin
            if selectedVoiceSource != .builtin || selectedVoice?.kind != .customVoice {
                selectVoiceSource(.builtin)
            }
            statusMessage = "已选择精品生成模型：\(model.displayName)"
        case .voiceClone:
            if selectedWorkflow != .multiRole {
                selectedWorkflow = .custom
            }
            if selectedWorkflow == .multiRole {
                selectedVoiceSource = .custom
                selectedVoiceID = nil
                statusMessage = "已选择对话生成 Base 模型：\(model.displayName)"
            } else if customVoices.isEmpty {
                selectedVoiceSource = .custom
                selectedVoiceID = nil
                statusMessage = "已选择 Base 模型：\(model.displayName)。请先在“克隆音色”或“创造音色”保存一个可复用音色。"
            } else if selectedVoiceSource != .custom || selectedVoice?.kind == .customVoice {
                selectVoiceSource(.custom)
                statusMessage = "已切换到克隆生成并选择 Base 模型：\(model.displayName)"
            } else {
                statusMessage = "已选择 Base 模型：\(model.displayName)"
            }
        case .voiceDesign:
            selectedWorkflow = .voiceDesign
            initializeVoiceDesignInstructionIfNeeded()
            statusMessage = "已选择 VoiceDesign：将使用声音风格描述 / system prompt 直接创造本段音色。"
        }
        normalizeScriptStudioControlsForSelectedWorkflow()
    }

    func fillCloneTranscriptFromCurrentScript() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "当前旁白文本为空，无法填入参考音频逐字稿"
            return
        }
        cloneReferenceText = trimmed
        statusMessage = "已用当前旁白文本填入参考音频逐字稿"
    }

    func fillCloneTranscriptExample() {
        cloneReferenceText = VoiceStudioDefaults.cloneReferenceTranscript
        statusMessage = "已填入录音示例句；录制参考音频时请读出同一句话"
    }

    func clearCloneTranscript() {
        cloneReferenceText = ""
        statusMessage = "已清空参考音频逐字稿"
    }

    func useScriptStudioReferenceTranscriptExample(_ text: String) {
        scriptStudioReferenceTextOverride = text.trimmingCharacters(in: .whitespacesAndNewlines)
        statusMessage = "已替换本次生成的参考逐字稿，请试听参考音频确认匹配"
    }

    func resetScriptStudioReferenceTranscriptOverride() {
        scriptStudioReferenceTextOverride = ""
        statusMessage = "已恢复为音色保存时绑定的参考逐字稿"
    }

    func selectMultiRoleVoice(speaker: String, voiceID: String?) {
        let normalizedSpeaker = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSpeaker.isEmpty else { return }
        guard let voiceID, let voice = customVoices.first(where: { $0.id == voiceID }) else {
            multiRoleVoiceBindings.removeValue(forKey: normalizedSpeaker)
            multiRoleVoicePreparationStatus[normalizedSpeaker] = nil
            statusMessage = "角色 \(normalizedSpeaker) 已取消音色绑定"
            return
        }
        multiRoleVoiceBindings[normalizedSpeaker] = voice.id
        let missingRequirements = reusableRoleVoiceMissingRequirements(voice)
        multiRoleVoicePreparationStatus[normalizedSpeaker] = missingRequirements.isEmpty
            ? .ready
            : .failed("绑定音色缺少 \(missingRequirements.joined(separator: "/"))")
        statusMessage = "角色 \(normalizedSpeaker) 已绑定到 \(voice.name)"
    }

    func isMultiRoleDesignedVoiceSelected(_ voice: VoiceProfile) -> Bool {
        multiRoleSelectedDesignedVoiceIDs.contains(voice.id)
    }

    func setMultiRoleDesignedVoice(_ voice: VoiceProfile, selected: Bool) {
        guard voice.kind == .voiceDesign else { return }
        if selected {
            multiRoleSelectedDesignedVoiceIDs.insert(voice.id)
            bindSelectedDesignedVoiceToMatchingRoles(voice)
            statusMessage = "已加入对话生成音色池：\(voice.name)"
        } else {
            multiRoleSelectedDesignedVoiceIDs.remove(voice.id)
            removeBindings(forVoiceID: voice.id)
            statusMessage = "已从对话生成音色池移除：\(voice.name)"
        }
    }

    func selectAllDesignedVoicesForMultiRole() {
        for voice in designedCustomVoices {
            multiRoleSelectedDesignedVoiceIDs.insert(voice.id)
            bindSelectedDesignedVoiceToMatchingRoles(voice)
        }
        statusMessage = designedCustomVoices.isEmpty ? "暂无可选择的创造音色" : "已选择全部创造音色"
    }

    func clearDesignedVoicesForMultiRole() {
        let selectedIDs = multiRoleSelectedDesignedVoiceIDs
        multiRoleSelectedDesignedVoiceIDs.removeAll()
        for voiceID in selectedIDs {
            removeBindings(forVoiceID: voiceID)
        }
        statusMessage = "已清空对话生成创造音色池"
    }

    func applyVoiceControlPreset(_ preset: VoiceControlPreset) {
        voiceControlProfile = preset.applying(to: voiceControlProfile)
        clearEditedGenerationControlInstruction()
        statusMessage = "已应用风格模板：\(preset.title)"
    }

    func randomizeVoiceControlProfile(for workflow: ScriptStudioWorkflow? = nil) {
        let targetWorkflow = workflow ?? selectedWorkflow
        voiceControlProfile = VoiceControlRandomizer.randomizedProfile(workflow: targetWorkflow)
        clearEditedGenerationControlInstruction()
        statusMessage = "已随机生成控制类型组合"
    }

    func randomizeGenerationControlInstruction() {
        guard currentModelInputPreview.showsInstructionEditor else {
            statusMessage = "当前工作流不支持指令控制；克隆生成的音色来自 RefAudio 和 RefText"
            return
        }
        voiceControlProfile = VoiceControlRandomizer.randomizedProfile(workflow: selectedWorkflow)
        let prompt = VoiceControlPromptCompiler.compile(
            profile: voiceControlProfile,
            workflow: selectedWorkflow
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            statusMessage = "随机生成失败：没有可用的控制类型组合"
            return
        }
        updateGenerationControlInstruction(prompt)
        statusMessage = "已随机生成并写入指令控制"
    }

    var voiceGrouping: VoiceLibraryGrouping {
        VoiceLibraryGrouping(voices: voices)
    }

    var builtinVoices: [VoiceProfile] {
        voiceGrouping.builtin
    }

    var customVoices: [VoiceProfile] {
        voiceGrouping.custom
    }

    var clonedCustomVoices: [VoiceProfile] {
        voiceGrouping.clonedCustom
    }

    var designedCustomVoices: [VoiceProfile] {
        voiceGrouping.designedCustom
    }

    var multiRoleSelectedDesignedVoices: [VoiceProfile] {
        designedCustomVoices.filter { multiRoleSelectedDesignedVoiceIDs.contains($0.id) }
    }

    var multiRoleUnselectedDesignedVoices: [VoiceProfile] {
        designedCustomVoices.filter { !multiRoleSelectedDesignedVoiceIDs.contains($0.id) }
    }

    var selectedVoiceChainLabel: String {
        guard let selectedVoice else { return "未选择音色" }
        return chainLabel(for: selectedVoice)
    }

    var selectedVoiceKind: VoiceKind? {
        selectedVoice?.kind
    }

    var scriptStudioPromptSet: ScriptStudioPromptSet {
        let deliveryPrompt: String
        switch selectedWorkflow {
        case .builtin:
            deliveryPrompt = instruct.trimmingCharacters(in: .whitespacesAndNewlines)
        case .multiRole:
            deliveryPrompt = ""
        case .custom, .voiceDesign:
            deliveryPrompt = ""
        }
        let identityPrompt = selectedWorkflow == .voiceDesign
            ? compiledVoiceControlPrompt
            : voiceIdentityDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return ScriptStudioPromptSet(
            deliveryStylePrompt: deliveryPrompt,
            voiceIdentityDescription: identityPrompt,
            editedDeliveryStylePrompt: editedDeliveryStylePrompt,
            editedVoiceIdentityDescription: editedVoiceIdentityDescription
        )
    }

    var generationInputPreview: ScriptStudioGenerationInputPreview {
        ScriptStudioGenerationInputPreview(
            workflow: selectedWorkflow,
            promptSet: scriptStudioPromptSet,
            synthesisText: text,
            segmentCount: segments.count
        )
    }

    var currentModelInputPreview: ScriptStudioModelInputPreview {
        if selectedWorkflow == .multiRole {
            return ScriptStudioModelInputPreview.make(
                workflow: .multiRole,
                text: text,
                languageChoice: scriptStudioLanguageChoice,
                speaker: "",
                instruct: "",
                refAudioPath: "",
                refText: ""
            )
        }
        let reference = referenceInput(for: selectedWorkflow == .custom ? selectedVoice : nil)
        return ScriptStudioModelInputPreview.make(
            workflow: selectedWorkflow,
            text: text,
            languageChoice: scriptStudioLanguageChoice,
            speaker: selectedWorkflow == .builtin ? speakerInput(for: selectedVoice) : "",
            instruct: editableGenerationControlInstruction,
            refAudioPath: reference.audio,
            refText: reference.text
        )
    }

    var activeVoiceControlProfile: VoiceControlProfile {
        var profile = voiceControlProfile
        if profile.language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile.language = displayLanguage(for: selectedVoice?.language ?? "Chinese")
        }
        profile.customPrompt = selectedWorkflow == .voiceDesign ? voiceIdentityDescription : instruct
        return profile
    }

    var compiledVoiceControlPrompt: String {
        VoiceControlPromptCompiler.compile(profile: activeVoiceControlProfile, workflow: selectedWorkflow)
    }

    var compiledVoiceDesignPrompt: String {
        var profile = voiceControlProfile
        if profile.language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            profile.language = "中文"
        }
        return VoiceControlPromptCompiler.compile(profile: profile, workflow: .voiceDesign)
    }

    var editableGenerationControlInstruction: String {
        scriptStudioPromptSet.activePrompt(for: selectedWorkflow)
    }

    var generationControlInstructionSourceLabel: String {
        let edited: String?
        switch selectedWorkflow {
        case .voiceDesign:
            edited = editedVoiceIdentityDescription
        case .builtin, .custom, .multiRole:
            edited = editedDeliveryStylePrompt
        }
        if let edited, !edited.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "手动编辑"
        }
        return editableGenerationControlInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "留白" : "默认指令"
    }

    func updateGenerationControlInstruction(_ value: String) {
        switch selectedWorkflow {
        case .voiceDesign:
            editedVoiceIdentityDescription = value
            voiceDesignInstructionDraftState.applyUserEdit(value)
            voiceIdentityDescription = value
        case .builtin, .custom:
            editedDeliveryStylePrompt = value
            if selectedWorkflow == .builtin {
                builtinInstructionDraftState.applyUserEdit(value)
                instruct = value
            }
        case .multiRole:
            statusMessage = "对话生成不使用角色控制指令；请在角色音色绑定中选择已保存音色"
            return
        }
        statusMessage = "已更新本次生成控制指令"
    }

    func applyCompiledVoiceControlPromptToScriptStudio() {
        let prompt = compiledVoiceControlPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            statusMessage = "当前声音控制还没有生成可应用的指令"
            return
        }
        updateGenerationControlInstruction(prompt)
        statusMessage = "已将创造音色指令应用到 Voice Studio"
    }

    func applyCompiledVoiceDesignPromptToScriptStudio() {
        let prompt = compiledVoiceDesignPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            statusMessage = "当前 VoiceDesign 控制还没有生成可应用的指令"
            return
        }
        selectedWorkflow = .voiceDesign
        editedVoiceIdentityDescription = prompt
        statusMessage = "已切换到 VoiceDesign，并将控制指令应用到 Voice Studio"
    }

    func resetGenerationControlInstructionToCompiled() {
        clearEditedGenerationControlInstruction()
        statusMessage = "已恢复默认控制指令"
    }

    func clearEditedGenerationControlInstruction() {
        switch selectedWorkflow {
        case .voiceDesign:
            editedVoiceIdentityDescription = nil
            voiceIdentityDescription = VoiceStudioDefaults.defaultVoiceDesignControlInstruction
            voiceDesignInstructionDraftState = VoiceInstructionDraftState(
                value: VoiceStudioDefaults.defaultVoiceDesignControlInstruction,
                didAutoInitialize: true,
                wasEditedByUser: false
            )
        case .builtin:
            editedDeliveryStylePrompt = nil
            instruct = VoiceStudioDefaults.defaultBuiltinControlInstruction
            builtinInstructionDraftState = VoiceInstructionDraftState(
                value: VoiceStudioDefaults.defaultBuiltinControlInstruction,
                didAutoInitialize: true,
                wasEditedByUser: false
            )
        case .custom:
            editedDeliveryStylePrompt = nil
        case .multiRole:
            break
        }
    }

    var scriptStudioWorkflowModels: [QwenModelSpec] {
        if selectedWorkflow == .multiRole {
            return catalog.baseModels
        }
        return catalog.models(forWorkflow: selectedWorkflow)
    }

    func scriptStudioModelDisplayName(for model: QwenModelSpec) -> String {
        model.resolvedDisplayName(localPath: modelStates[model.id]?.localPath)
    }

    var compatibleModelsForSelectedVoice: [QwenModelSpec] {
        guard let selectedVoice else { return catalog.models }
        return catalog.models(for: capability(for: selectedVoice))
    }

    var selectedScriptStudioModel: QwenModelSpec? {
        catalog.models.first { $0.id == selectedModelID }
    }

    var isVoiceDesignModelSelected: Bool {
        selectedWorkflow == .voiceDesign || selectedScriptStudioModel?.capability == .voiceDesign
    }

    var activeGenerationModelID: String {
        if selectedWorkflow == .voiceDesign {
            return selectedModelID
        }
        guard let selectedVoice else { return selectedModelID }
        return modelID(for: selectedVoice)
    }

    var multiRoleVoicePreparationItems: [MultiRoleVoicePreparationItem] {
        let script = SpeakerTaggedTextNormalizer.script(from: text)
        var firstUtteranceBySpeaker: [String: String] = [:]
        for utterance in script.utterances {
            guard let speaker = utterance.speaker?.trimmingCharacters(in: .whitespacesAndNewlines), !speaker.isEmpty else {
                continue
            }
            if firstUtteranceBySpeaker[speaker] == nil {
                firstUtteranceBySpeaker[speaker] = utterance.spokenText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return SpeakerTaggedTextNormalizer.roleNames(from: text).map { speaker in
            let reusableVoice = roleReusableVoice(for: speaker)
            let payload = reusableVoice.map { voicePayload(for: $0).mapValues { String(describing: $0) } } ?? [:]
            let referenceAudioPath = payload["ref_audio"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let boundReferenceText = payload["ref_text"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let missingRequirements = reusableVoice.map { reusableRoleVoiceMissingRequirements($0) } ?? ["绑定音色"]
            let status = multiRoleVoicePreparationStatus[speaker]
                ?? (reusableVoice == nil ? .missing : (missingRequirements.isEmpty ? .ready : .failed("缺少 \(missingRequirements.joined(separator: "/"))")))
            return MultiRoleVoicePreparationItem(
                speaker: speaker,
                instruction: "Base 复用只使用绑定音色的 ref_audio/ref_text；不传角色控制指令。",
                referenceText: firstUtteranceBySpeaker[speaker] ?? "",
                boundVoiceID: reusableVoice?.id,
                boundVoiceName: reusableVoice?.name,
                sourceKind: reusableVoice.map { multiRoleSourceKind(for: $0, speaker: speaker) } ?? .unbound,
                status: status,
                referenceAudioPath: referenceAudioPath?.isEmpty == false ? referenceAudioPath : nil,
                boundReferenceText: boundReferenceText?.isEmpty == false ? boundReferenceText : nil,
                missingRequirements: missingRequirements
            )
        }
    }

    func generateAllSegments() {
        guard requireWorkspaceReady(action: "生成音频") else { return }
        guard !isGeneratingAllSegments else {
            statusMessage = "全文生成队列正在运行"
            return
        }
        let queuedSegments = segments
        guard !queuedSegments.isEmpty else {
            statusMessage = "没有可生成的段落"
            return
        }
        guard !hasRoleRoutedScript || selectedWorkflow == .multiRole else {
            statusMessage = "检测到多角色脚本。请先切换到“对话生成”，再绑定或准备角色音色并生成全文。"
            return
        }
        guard selectedWorkflow != .multiRole || hasRoleRoutedScript else {
            statusMessage = "对话生成需要在合成文本里使用“角色名: 台词”，并为每个角色绑定已保存音色。"
            return
        }
        isGeneratingAllSegments = true
        fullGeneratedAudioPath = nil
        let queuedRoleSpeakers = Set(queuedSegments.compactMap { roleSpeaker(for: $0) })
        if selectedWorkflow == .multiRole {
            statusMessage = "正在检查对话角色音色，共 \(queuedRoleSpeakers.count) 个角色"
            guard validateBoundMultiRoleVoices(for: queuedRoleSpeakers) else {
                isGeneratingAllSegments = false
                return
            }
        }
        let queuedWorkflow = selectedWorkflow
        statusMessage = "全文生成队列启动，共 \(queuedSegments.count) 段"

        generationQueueTask = Task.detached { [weak self, queuedSegments, queuedWorkflow] in
            var summary = GenerationQueueSummary(total: queuedSegments.count)
            for segment in queuedSegments {
                if Task.isCancelled {
                    summary.cancelled = true
                    break
                }
                guard let prepared = await MainActor.run(body: {
                    self?.prepareGeneration(for: segment)
                }) else {
                    summary.skipped += 1
                    continue
                }
                await MainActor.run {
                    self?.statusMessage = "全文生成 \(segment.index + 1)/\(queuedSegments.count)：\(segment.text.prefix(18))"
                }
                do {
                    let response = try Self.performGenerationCall(input: prepared.callInput, backend: prepared.backend)
                    let succeeded = await MainActor.run {
                        self?.handleGenerationResponse(response, for: prepared.segment, voice: prepared.voice, modelID: prepared.modelID, prompt: prepared.callInput.instruct, recordMode: prepared.recordMode) ?? false
                    }
                    if succeeded {
                        summary.succeeded += 1
                    } else {
                        summary.failed += 1
                    }
                } catch {
                    await MainActor.run {
                        self?.handleGenerationFailure(error, for: prepared.segment)
                    }
                    summary.failed += 1
                }
                if Task.isCancelled {
                    summary.cancelled = true
                    break
                }
            }
            let mergeInput = await MainActor.run { () -> FullAudioMergeInput? in
                guard let self else { return nil }
                let isMultiRoleMerge = queuedWorkflow == .multiRole
                let outputName = isMultiRoleMerge
                    ? "\(Self.safeFileStem(self.projectTitle))-dialogue-full.webm"
                    : "\(Self.safeFileStem(self.projectTitle))-full.webm"
                let plan = GenerationQueueMergePlanner.plan(
                    summary: summary,
                    orderedSegmentIDs: queuedSegments.map(\.id),
                    audioPathsBySegmentID: self.generatedAudioPaths,
                    outputName: outputName,
                    gapSeconds: isMultiRoleMerge ? Self.multiRoleConcatGapSeconds : 0
                )
                guard let plan else { return nil }
                self.statusMessage = "正在按段落顺序合并完整音频，共 \(plan.paths.count) 段"
                return FullAudioMergeInput(
                    backend: self.backend,
                    paths: plan.paths,
                    outputName: plan.outputName,
                    gapSeconds: plan.gapSeconds
                )
            }
            var mergedPath: String?
            var mergeError: String?
            if let mergeInput {
                do {
                    let response = try Self.performAudioConcat(input: mergeInput)
                    mergedPath = Self.audioPath(fromConcatResponse: response)
                } catch {
                    mergeError = error.localizedDescription
                }
            }
            await MainActor.run {
                self?.generationQueueTask = nil
                self?.isGeneratingAllSegments = false
                if let mergedPath {
                    guard let self else { return }
                    let absolutePath = self.resolvedAudioURL(mergedPath).path
                    self.fullGeneratedAudioPath = absolutePath
                    self.saveMergedFullGeneration(
                        audioPath: absolutePath,
                        workflow: queuedWorkflow,
                        segmentCount: queuedSegments.count,
                        gapSeconds: mergeInput?.gapSeconds ?? 0
                    )
                    self.refreshGenerationHistory()
                    self.statusMessage = "\(summary.statusText)，已合并为 1 个完整 WebM"
                } else if let mergeError {
                    self?.statusMessage = "\(summary.statusText)，但全文音频合并失败：\(mergeError)"
                } else {
                    self?.statusMessage = summary.statusText
                }
            }
        }
    }

    func cancelAllGeneration() {
        guard isGeneratingAllSegments else {
            statusMessage = "当前没有运行中的全文生成队列"
            return
        }
        generationQueueTask?.cancel()
        statusMessage = "正在取消全文生成：当前段落完成后停止"
    }

    func generate(segment: TextSegment) {
        guard let prepared = prepareGeneration(for: segment) else {
            return
        }
        statusMessage = "正在生成段落 \(segment.index + 1)"
        Task.detached { [weak self, prepared] in
            do {
                let response = try Self.performGenerationCall(input: prepared.callInput, backend: prepared.backend)
                _ = await self?.handleGenerationResponse(response, for: prepared.segment, voice: prepared.voice, modelID: prepared.modelID, prompt: prepared.callInput.instruct, recordMode: prepared.recordMode)
            } catch {
                await self?.handleGenerationFailure(error, for: prepared.segment)
            }
        }
    }

    private func prepareGeneration(for segment: TextSegment) -> PreparedGenerationContext? {
        guard requireWorkspaceReady(action: "生成音频") else { return nil }
        guard !generatingSegmentIDs.contains(segment.id) else {
            return nil
        }
        let selectedModel = selectedScriptStudioModel
        let usesVoiceDesign = selectedWorkflow == .voiceDesign || selectedModel?.capability == .voiceDesign
        let voice: VoiceProfile
        let generationMethod: String
        let generationModelID: String
        let promptSet = scriptStudioPromptSet
        let scriptRequiresRoleRouting = hasRoleRoutedScript
        let roleSpeaker = roleSpeaker(for: segment)
        let usesRoleRouting = roleSpeaker != nil && scriptRequiresRoleRouting
        let usesMultiRoleRouting = selectedWorkflow == .multiRole && usesRoleRouting
        let usesDirectVoiceDesign = !usesRoleRouting && usesVoiceDesign
        if scriptRequiresRoleRouting && selectedWorkflow != .multiRole {
            let message = "检测到多角色脚本。请切换到“对话生成”，绑定角色音色后用 Base 逐句生成。"
            generationErrors[segment.id] = message
            statusMessage = message
            return nil
        }
        if selectedWorkflow == .multiRole && !usesRoleRouting {
            let message = "对话生成中的每段台词都需要“角色名: 台词”标签，并为该角色绑定已保存音色。"
            generationErrors[segment.id] = message
            statusMessage = message
            return nil
        }
        if usesMultiRoleRouting {
            guard let speaker = roleSpeaker, !speaker.isEmpty else {
                let message = "当前段落缺少角色标签，无法按对话生成。"
                generationErrors[segment.id] = message
                statusMessage = message
                return nil
            }
            guard let reusableVoice = roleReusableVoice(for: speaker) else {
                let message = "角色 \(speaker) 未绑定音色，请在角色音色绑定里选择已保存的克隆音色或创造音色。"
                generationErrors[segment.id] = message
                statusMessage = message
                return nil
            }
            let missingRequirements = reusableRoleVoiceMissingRequirements(reusableVoice)
            guard missingRequirements.isEmpty else {
                let message = "角色 \(speaker) 绑定的音色缺少 \(missingRequirements.joined(separator: "/"))，无法用于 Base 复用。"
                multiRoleVoicePreparationStatus[speaker] = .failed(message)
                generationErrors[segment.id] = message
                statusMessage = message
                return nil
            }
            multiRoleVoicePreparationStatus[speaker] = .ready
            voice = reusableVoice
            generationMethod = "tts.generate_voice_clone"
            generationModelID = catalog.preferredModelID(
                for: .voiceClone,
                selectedModelID: selectedModelID,
                readyModelIDs: currentReadyModelIDs
            )
        } else if usesDirectVoiceDesign {
            voice = VoiceProfile(
                id: "voice-design-direct",
                name: roleSpeaker.map { "VoiceDesign · \($0)" } ?? "VoiceDesign 即时音色",
                kind: .voiceDesign,
                language: selectedVoice?.language ?? "Chinese",
                instruct: voiceIdentityDescription
            )
            generationMethod = "tts.generate_voice_design"
            generationModelID = selectedModel?.id ?? selectedModelID
        } else {
            guard let selectedVoice else {
                statusMessage = "请先选择音色"
                return nil
            }
            voice = selectedVoice
            generationMethod = method(for: selectedVoice)
            generationModelID = modelID(for: selectedVoice)
            selectedModelID = generationModelID
        }
        let availability = modelAvailability(for: generationModelID)
        guard availability.available else {
            let message = "模型未就绪：\(availability.path)。请在“模型”中下载或选择本地路径。"
            generationErrors[segment.id] = message
            statusMessage = message
            return nil
        }
        var voicePayload = usesDirectVoiceDesign ? [:] : voicePayload(for: voice)
        if !usesDirectVoiceDesign, !usesMultiRoleRouting, voice.kind == .customVoice, voicePayload["speaker"] == nil {
            voicePayload["speaker"] = voice.speaker ?? voice.name
        }
        if !usesMultiRoleRouting, let missing = promptSet.missingRequirement(for: selectedWorkflow) {
            let message = "VoiceDesign 需要先填写\(missing)。"
            generationErrors[segment.id] = message
            statusMessage = message
            return nil
        }
        let activePrompt = promptSet.activePrompt(for: usesDirectVoiceDesign ? .voiceDesign : selectedWorkflow)
        let rolePrompt = usesDirectVoiceDesign ? roleInstruction(for: segment) : nil
        let resolvedPrompt = usesMultiRoleRouting
            ? ""
            : (rolePrompt ?? activePrompt)
        let synthesisText = usesMultiRoleRouting
            ? segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            : SpeakerTaggedTextNormalizer.synthesisText(from: segment.text)
        guard !synthesisText.isEmpty else {
            let message = "段落 \(segment.index + 1) 只有角色定义或空文本，已跳过生成"
            generationErrors[segment.id] = message
            statusMessage = message
            return nil
        }
        let reference = referenceInput(for: !usesDirectVoiceDesign && voice.kind != .customVoice ? voice : nil)
        let modelInput = ScriptStudioModelInputPreview.make(
            workflow: usesMultiRoleRouting ? .multiRole : (usesDirectVoiceDesign ? .voiceDesign : selectedWorkflow),
            text: synthesisText,
            languageChoice: scriptStudioLanguageChoice,
            speaker: !usesDirectVoiceDesign && !usesMultiRoleRouting && voice.kind == .customVoice ? speakerInput(for: voice) : "",
            instruct: resolvedPrompt,
            refAudioPath: reference.audio,
            refText: reference.text,
            preserveRoleLabels: false
        )
        if !modelInput.missingRequirements.isEmpty {
            let message = "模型输入缺失：\(modelInput.missingRequirements.joined(separator: "、"))"
            generationErrors[segment.id] = message
            statusMessage = message
            return nil
        }
        let callInput = GenerationCallInput(
            method: generationMethod,
            route: usesMultiRoleRouting ? "multi_role_reuse" : "",
            text: modelInput.text,
            language: modelInput.requestLanguage,
            modelID: generationModelID,
            modelPath: modelStates[generationModelID]?.localPath,
            voiceAssetID: voice.id,
            voice: voicePayload.mapValues { String(describing: $0) },
            instruct: modelInput.instruct,
            seed: usesMultiRoleRouting
                ? SpeakerTaggedTextNormalizer.deterministicSeed(speaker: roleSpeaker ?? "", instruction: voice.id)
                : nil
        )
        generationErrors[segment.id] = nil
        beginGenerationProgress(for: segment)
        return PreparedGenerationContext(
            callInput: callInput,
            backend: backend,
            segment: segment,
            voice: voice,
            modelID: generationModelID,
            recordMode: usesMultiRoleRouting ? "multi_role_reuse" : voice.kind.rawValue
        )
    }

    func generateDiagnosticTone(segment: TextSegment) {
        guard requireWorkspaceReady(action: "生成诊断音") else { return }
        guard !generatingSegmentIDs.contains(segment.id) else {
            return
        }
        beginGenerationProgress(for: segment)
        let backend = backend
        Task.detached { [weak self, backend, segment] in
            do {
                let response = try backend.request(
                    method: "diagnostic.generate_tone",
                    params: ["text": segment.text, "model_id": "diagnostic-tone"]
                )
                await MainActor.run {
                    guard let self else { return }
                    let voice = self.selectedVoice ?? VoiceProfile(name: "诊断模式", kind: .customVoice, language: "Chinese")
                    _ = self.handleGenerationResponse(response, for: segment, voice: voice, modelID: "diagnostic-tone", prompt: "诊断音")
                }
            } catch {
                await self?.handleGenerationFailure(error, for: segment)
            }
        }
    }

    func play(segment: TextSegment) {
        guard let path = generatedAudioPaths[segment.id] else {
            statusMessage = "这个段落还没有生成音频"
            return
        }
        let resumeTime = pausedPlaybackPoint?.resumeTime(forAudioID: segment.id, audioPath: path)
        guard startAudioPlayback(path: path, resumeTime: resumeTime) else { return }
        playingSegmentID = segment.id
        playingGenerationID = nil
        playingAudioItemID = nil
        currentPlaybackPath = path
        currentPlaybackAudioID = segment.id
        pausedPlaybackPoint = nil
        startPlaybackProgress(for: segment.id)
    }

    func play(record: GenerationRecord) {
        guard !record.audioPath.isEmpty else {
            statusMessage = "这条生成记录没有音频文件"
            return
        }
        let resumeTime = pausedPlaybackPoint?.resumeTime(forAudioID: record.id, audioPath: record.audioPath)
        guard startAudioPlayback(path: record.audioPath, resumeTime: resumeTime) else { return }
        playingGenerationID = record.id
        playingSegmentID = nil
        playingAudioItemID = nil
        currentPlaybackPath = record.audioPath
        currentPlaybackAudioID = record.id
        pausedPlaybackPoint = nil
        startPlaybackProgress(for: record.id)
    }

    func play(audioItem: AudioPlaybackItem) {
        guard !audioItem.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "这条音频路径为空"
            return
        }
        let resumeTime = pausedPlaybackPoint?.resumeTime(forAudioID: audioItem.id, audioPath: audioItem.path)
        guard startAudioPlayback(path: audioItem.path, resumeTime: resumeTime) else { return }
        playingAudioItemID = audioItem.id
        playingSegmentID = nil
        playingGenerationID = nil
        currentPlaybackPath = audioItem.path
        currentPlaybackAudioID = audioItem.id
        pausedPlaybackPoint = nil
        startPlaybackProgress(for: audioItem.id)
    }

    func togglePlay(segment: TextSegment) {
        if playingSegmentID == segment.id, audioPlayer?.isPlaying == true {
            pausePlayback()
        } else {
            play(segment: segment)
        }
    }

    func togglePlay(record: GenerationRecord) {
        if playingGenerationID == record.id, audioPlayer?.isPlaying == true {
            pausePlayback()
        } else {
            play(record: record)
        }
    }

    func togglePlay(audioItem: AudioPlaybackItem) {
        if playingAudioItemID == audioItem.id, audioPlayer?.isPlaying == true {
            pausePlayback()
        } else {
            play(audioItem: audioItem)
        }
    }

    func pausePlayback() {
        rememberPausedPlaybackPoint()
        if isPlayingAllGenerated {
            rememberPausedPlayAllState()
        }
        audioPlayer?.pause()
        isPlayingAllGenerated = false
        playAllGeneratedTask?.cancel()
        playAllGeneratedTask = nil
        statusMessage = "播放已暂停"
        playbackProgressTask?.cancel()
        playingSegmentID = nil
        playingGenerationID = nil
        playingAudioItemID = nil
        currentPlaybackAudioID = nil
    }

    private func stopPlaybackForWorkspaceSwitch() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackProgressTask?.cancel()
        playAllGeneratedTask?.cancel()
        playbackProgressTask = nil
        playAllGeneratedTask = nil
        playingSegmentID = nil
        playingGenerationID = nil
        playingAudioItemID = nil
        isPlayingAllGenerated = false
        currentPlaybackPath = nil
        currentPlaybackAudioID = nil
        pausedPlaybackPoint = nil
        pausedPlayAllState = nil
        playAllQueuePaths = []
        playAllCurrentIndex = nil
        audioPlaybackProgress = [:]
        audioPlaybackDuration = [:]
    }

    nonisolated private static func waitUntilRecordingFileIsStable(at url: URL) async -> Bool {
        let policy = RecordingFileStabilityPolicy()
        var recentSizes: [Int64] = []
        for _ in 0..<20 {
            let size = fileSize(at: url)
            if size > 0 {
                recentSizes.append(size)
                recentSizes = Array(recentSizes.suffix(policy.stableSampleCount))
                if policy.isReady(recentSizes: recentSizes) {
                    return true
                }
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return policy.isReady(recentSizes: recentSizes)
    }

    nonisolated private static func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    func isPlaying(segment: TextSegment) -> Bool {
        playingSegmentID == segment.id && audioPlayer?.isPlaying == true
    }

    func isPlaying(record: GenerationRecord) -> Bool {
        playingGenerationID == record.id && audioPlayer?.isPlaying == true
    }

    func isPlaying(audioItem: AudioPlaybackItem) -> Bool {
        playingAudioItemID == audioItem.id && audioPlayer?.isPlaying == true
    }

    func audioDurationText(audioID: String? = nil, path: String?) -> String {
        AudioDurationFormatter.displayText(audioDuration(audioID: audioID, path: path))
    }

    func audioDurationLabel(audioID: String? = nil, path: String?) -> String {
        AudioDurationFormatter.labelText(audioDuration(audioID: audioID, path: path))
    }

    var generatedPlaybackDurationLabel: String {
        if let fullGeneratedAudioPath, FileManager.default.fileExists(atPath: fullGeneratedAudioPath) {
            return AudioDurationFormatter.labelText(audioDuration(path: fullGeneratedAudioPath))
        }
        let durations = segments.compactMap { segment in
            generatedAudioPaths[segment.id].flatMap { audioDuration(path: $0) }
        }
        guard !durations.isEmpty else { return AudioDurationFormatter.labelText(nil) }
        return AudioDurationFormatter.labelText(durations.reduce(0, +))
    }

    var hasPlayableGeneratedAudio: Bool {
        if let fullGeneratedAudioPath, FileManager.default.fileExists(atPath: fullGeneratedAudioPath) {
            return true
        }
        return segments.contains { segment in
            guard let path = generatedAudioPaths[segment.id] else { return false }
            return FileManager.default.fileExists(atPath: resolvedAudioURL(path).path)
        }
    }

    var hasMergedFullGeneratedAudio: Bool {
        guard let fullGeneratedAudioPath else { return false }
        return FileManager.default.fileExists(atPath: fullGeneratedAudioPath)
    }

    var canExportFullGeneratedAudio: Bool {
        hasPlayableGeneratedAudio && !isGeneratingAllSegments && !isMergingFullGeneratedAudio
    }

    func deleteGeneratedAudio(for segment: TextSegment) {
        guard let path = generatedAudioPaths[segment.id] else {
            statusMessage = "这个段落没有可删除的生成音频"
            return
        }
        let url = resolvedAudioURL(path)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            generatedAudioPaths[segment.id] = nil
            generatedModelIDs[segment.id] = nil
            generatedVoiceNames[segment.id] = nil
            generatedInstructions[segment.id] = nil
            generatedRuntimes[segment.id] = nil
            generationErrors[segment.id] = nil
            generationProgress[segment.id] = nil
            generationProgressLabel[segment.id] = nil
            if playingSegmentID == segment.id {
                audioPlayer?.stop()
                playbackProgressTask?.cancel()
                playingSegmentID = nil
                currentPlaybackAudioID = nil
            }
            clearPausedPlaybackPoint(for: segment.id)
            audioPlaybackProgress[segment.id] = nil
            audioPlaybackDuration[segment.id] = nil
            statusMessage = "段落 \(segment.index + 1) 的生成音频已删除"
        } catch {
            statusMessage = "删除失败：\(error.localizedDescription)"
        }
    }

    func resultState(for segment: TextSegment) -> SegmentResultState {
        SegmentResultState(
            audioPath: generatedAudioPaths[segment.id],
            error: generationErrors[segment.id]
        )
    }

    func playAudio(path: String) {
        togglePlay(audioItem: .file(path: path, context: "legacy"))
    }

    private func audioDuration(audioID: String? = nil, path: String?) -> Double? {
        if let audioID, let duration = audioPlaybackDuration[audioID] {
            return duration
        }
        return audioDuration(path: path)
    }

    private func audioDuration(path: String?) -> Double? {
        guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let url = resolvedAudioURL(path)
        if let cached = audioFileDurationCache[url.path] ?? audioFileDurationCache[path] {
            return cached
        }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        if url.pathExtension.lowercased() != "wav", let duration = probeAudioDuration(url) {
            audioFileDurationCache[url.path] = duration
            audioFileDurationCache[path] = duration
            return duration
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            let duration = max(player.duration, 0)
            audioFileDurationCache[url.path] = duration
            audioFileDurationCache[path] = duration
            return duration
        } catch {
            return nil
        }
    }

    @discardableResult
    private func startAudioPlayback(path: String, resumeTime: Double?) -> Bool {
        let url = resolvedAudioURL(path)
        do {
            let playableURL = try playableAudioURL(for: url)
            audioPlayer = try AVAudioPlayer(contentsOf: playableURL)
            audioPlayer?.prepareToPlay()
            if let duration = audioPlayer?.duration {
                audioFileDurationCache[url.path] = duration
                audioFileDurationCache[path] = duration
            }
            if let resumeTime, let duration = audioPlayer?.duration {
                audioPlayer?.currentTime = min(max(resumeTime, 0), duration)
            }
            audioPlayer?.play()
            statusMessage = resumeTime == nil ? "正在播放 \(url.lastPathComponent)" : "从暂停位置继续播放 \(url.lastPathComponent)"
            return true
        } catch {
            statusMessage = "播放失败：\(error.localizedDescription)"
            return false
        }
    }

    private func playableAudioURL(for sourceURL: URL) throws -> URL {
        guard sourceURL.pathExtension.lowercased() != "wav" else {
            return sourceURL
        }
        let playbackDirectory = paths.cache.appendingPathComponent("playback", isDirectory: true)
        try FileManager.default.createDirectory(at: playbackDirectory, withIntermediateDirectories: true)
        let hash = String(sourceURL.path.hashValue, radix: 16).replacingOccurrences(of: "-", with: "n")
        let destination = playbackDirectory.appendingPathComponent("\(sourceURL.deletingPathExtension().lastPathComponent)-\(hash).wav")
        if FileManager.default.fileExists(atPath: destination.path),
           let sourceDate = try? sourceURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
           let destinationDate = try? destination.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
           destinationDate >= sourceDate {
            return destination
        }
        _ = try Self.runAudioTool(
            "ffmpeg",
            arguments: [
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                "-i",
                sourceURL.path,
                "-ac",
                "1",
                "-ar",
                "24000",
                "-f",
                "wav",
                destination.path
            ]
        )
        return destination
    }

    private func probeAudioDuration(_ url: URL) -> Double? {
        guard url.pathExtension.lowercased() == Self.userAudioExtension else { return nil }
        guard let output = try? Self.runAudioTool(
            "ffprobe",
            arguments: [
                "-v",
                "error",
                "-show_entries",
                "format=duration",
                "-of",
                "default=noprint_wrappers=1:nokey=1",
                url.path
            ]
        ) else {
            return nil
        }
        return Double(output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    nonisolated private static func runAudioTool(_ name: String, arguments: [String]) throws -> String {
        guard let executableURL = audioToolExecutableURL(name) else {
            throw NSError(
                domain: "VoiceStudioAudioTool",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "需要安装 \(name)。音频播放、转码和合并依赖 ffmpeg/ffprobe。"]
            )
        }
        let process = Process()
        process.executableURL = executableURL
        process.arguments = executableURL.path == "/usr/bin/env" ? [name] + arguments : arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "VoiceStudioAudioTool",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(name) 执行失败" : text.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
        }
        return text
    }

    nonisolated private static func audioToolExecutableURL(_ name: String) -> URL? {
        if let runtimeURL = VoiceStudioRuntimeEnvironment.executableURL(named: name) {
            return runtimeURL
        }
        let fixedPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)"
        ]
        for path in fixedPaths where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return URL(fileURLWithPath: "/usr/bin/env")
    }

    func seekPlayback(segment: TextSegment, progress: Double) {
        let clamped = min(max(progress, 0), 1)
        if let player = audioPlayer, playingSegmentID == segment.id {
            player.currentTime = player.duration * clamped
            audioPlaybackProgress[segment.id] = clamped
            audioPlaybackDuration[segment.id] = player.duration
            return
        }
        guard let path = generatedAudioPaths[segment.id], let duration = audioDuration(audioID: segment.id, path: path), duration > 0 else { return }
        let point = PlaybackResumePoint(audioID: segment.id, audioPath: path, currentTime: duration * clamped, duration: duration)
        pausedPlaybackPoint = point
        audioPlaybackProgress[segment.id] = point.progress
        audioPlaybackDuration[segment.id] = duration
    }

    func seekPlayback(record: GenerationRecord, progress: Double) {
        let clamped = min(max(progress, 0), 1)
        if let player = audioPlayer, playingGenerationID == record.id {
            player.currentTime = player.duration * clamped
            audioPlaybackProgress[record.id] = clamped
            audioPlaybackDuration[record.id] = player.duration
            return
        }
        guard let duration = audioDuration(audioID: record.id, path: record.audioPath), duration > 0 else { return }
        let point = PlaybackResumePoint(audioID: record.id, audioPath: record.audioPath, currentTime: duration * clamped, duration: duration)
        pausedPlaybackPoint = point
        audioPlaybackProgress[record.id] = point.progress
        audioPlaybackDuration[record.id] = duration
    }

    func seekPlayback(audioItem: AudioPlaybackItem, progress: Double) {
        let clamped = min(max(progress, 0), 1)
        if let player = audioPlayer, playingAudioItemID == audioItem.id {
            player.currentTime = player.duration * clamped
            audioPlaybackProgress[audioItem.id] = clamped
            audioPlaybackDuration[audioItem.id] = player.duration
            return
        }
        guard let duration = audioDuration(audioID: audioItem.id, path: audioItem.path), duration > 0 else { return }
        let point = PlaybackResumePoint(audioID: audioItem.id, audioPath: audioItem.path, currentTime: duration * clamped, duration: duration)
        pausedPlaybackPoint = point
        audioPlaybackProgress[audioItem.id] = point.progress
        audioPlaybackDuration[audioItem.id] = duration
    }

    private func startPlaybackProgress(for audioID: String) {
        playbackProgressTask?.cancel()
        guard let player = audioPlayer else { return }
        audioPlaybackDuration[audioID] = player.duration
        audioPlaybackProgress[audioID] = player.duration > 0 ? player.currentTime / player.duration : 0
        playbackProgressTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 150_000_000)
                await MainActor.run {
                    guard let self, self.currentPlaybackAudioID == audioID, let player = self.audioPlayer else { return }
                    self.audioPlaybackDuration[audioID] = player.duration
                    self.audioPlaybackProgress[audioID] = player.duration > 0 ? player.currentTime / player.duration : 0
                    if !player.isPlaying {
                        if player.duration > 0, player.currentTime >= player.duration - 0.15 {
                            self.clearPausedPlaybackPoint(for: audioID)
                        }
                        if self.playingSegmentID == audioID {
                            self.playingSegmentID = nil
                        }
                        if self.playingGenerationID == audioID {
                            self.playingGenerationID = nil
                        }
                        if self.playingAudioItemID == audioID {
                            self.playingAudioItemID = nil
                        }
                        if self.currentPlaybackAudioID == audioID {
                            self.currentPlaybackAudioID = nil
                        }
                    }
                }
                if await MainActor.run(body: { self?.currentPlaybackAudioID != audioID }) {
                    break
                }
            }
        }
    }

    private func rememberPausedPlaybackPoint() {
        guard
            let player = audioPlayer,
            let audioID = playingSegmentID ?? playingGenerationID ?? playingAudioItemID,
            let currentPlaybackPath
        else {
            return
        }
        let point = PlaybackResumePoint(
            audioID: audioID,
            audioPath: currentPlaybackPath,
            currentTime: player.currentTime,
            duration: player.duration
        )
        guard point.resumeTime(forAudioID: audioID, audioPath: currentPlaybackPath) != nil else {
            pausedPlaybackPoint = nil
            return
        }
        pausedPlaybackPoint = point
        audioPlaybackDuration[audioID] = point.duration
        audioPlaybackProgress[audioID] = point.progress
    }

    private func clearPausedPlaybackPoint(for audioID: String) {
        if pausedPlaybackPoint?.audioID == audioID {
            pausedPlaybackPoint = nil
        }
    }

    private func rememberPausedPlayAllState() {
        guard
            let player = audioPlayer,
            let index = playAllCurrentIndex,
            playAllQueuePaths.indices.contains(index)
        else {
            pausedPlayAllState = nil
            return
        }
        let state = PlaybackQueueResumeState(
            itemIndex: index,
            itemPath: playAllQueuePaths[index],
            currentTime: player.currentTime,
            duration: player.duration
        )
        guard state.resumePlan(for: playAllQueuePaths) != nil else {
            pausedPlayAllState = nil
            return
        }
        pausedPlayAllState = state
    }

    var playAllControlState: PlaybackQueueControlState {
        PlaybackQueueControlState(isPlaying: isPlayingAllGenerated)
    }

    func togglePlayAllGenerated() {
        if playAllControlState.shouldPauseOnTap {
            pauseAllGeneratedPlayback()
        } else {
            playAllGenerated()
        }
    }

    func pauseAllGeneratedPlayback() {
        guard isPlayingAllGenerated else {
            statusMessage = "当前没有正在播放的全文队列"
            return
        }
        rememberPausedPlayAllState()
        playAllGeneratedTask?.cancel()
        playAllGeneratedTask = nil
        audioPlayer?.pause()
        isPlayingAllGenerated = false
        statusMessage = "全文播放已暂停"
    }

    func playAllGenerated() {
        if let fullGeneratedAudioPath, FileManager.default.fileExists(atPath: fullGeneratedAudioPath) {
            playAudio(path: fullGeneratedAudioPath)
            statusMessage = "正在播放完整合并音频"
            return
        }
        let paths = segments.compactMap { generatedAudioPaths[$0.id] }
        guard !paths.isEmpty else {
            statusMessage = "还没有可播放的生成音频"
            return
        }
        let resumePlan = pausedPlayAllState?.resumePlan(for: paths)
        let startIndex = resumePlan?.startIndex ?? 0
        let resumeTime = resumePlan?.resumeTime
        let urls = paths.enumerated().dropFirst(startIndex).map { (index, path) in
            (index: index, path: path, url: resolvedAudioURL(path))
        }
        playAllGeneratedTask?.cancel()
        playAllQueuePaths = paths
        playAllCurrentIndex = nil
        currentPlaybackAudioID = nil
        pausedPlayAllState = nil
        isPlayingAllGenerated = true
        statusMessage = resumePlan == nil ? "正在播放全文" : "从暂停位置继续播放全文"
        playAllGeneratedTask = Task { [weak self] in
            guard let self else { return }
            for item in urls {
                if Task.isCancelled { break }
                do {
                    let playableURL = try self.playableAudioURL(for: item.url)
                    self.audioPlayer = try AVAudioPlayer(contentsOf: playableURL)
                    self.audioPlayer?.prepareToPlay()
                    if item.index == startIndex, let resumeTime, let duration = self.audioPlayer?.duration {
                        self.audioPlayer?.currentTime = min(max(resumeTime, 0), duration)
                    }
                    self.currentPlaybackPath = item.path
                    self.playAllCurrentIndex = item.index
                    self.audioPlayer?.play()
                    self.playingSegmentID = nil
                    self.playingGenerationID = nil
                    while self.audioPlayer?.isPlaying == true {
                        try? await Task.sleep(nanoseconds: 120_000_000)
                        if Task.isCancelled { break }
                    }
                    if Task.isCancelled { break }
                } catch {
                    self.isPlayingAllGenerated = false
                    self.playAllGeneratedTask = nil
                    self.statusMessage = "播放队列中断：\(error.localizedDescription)"
                    return
                }
            }
            self.isPlayingAllGenerated = false
            self.playAllGeneratedTask = nil
            self.playAllCurrentIndex = nil
            self.playAllQueuePaths = []
            if Task.isCancelled {
                self.statusMessage = "全文播放已暂停"
            } else {
                self.pausedPlayAllState = nil
                self.statusMessage = "播放队列完成"
            }
        }
    }

    func export(segment: TextSegment) {
        guard let path = generatedAudioPaths[segment.id] else {
            statusMessage = "这个段落还没有生成音频"
            return
        }
        let source = resolvedAudioURL(path)
        guard FileManager.default.fileExists(atPath: source.path) else {
            statusMessage = "导出失败：音频文件不存在"
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.userAudioContentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = exportFileName(for: segment)
        if panel.runModal() == .OK, let destination = panel.url {
            copyAudioFile(from: source, to: destination, successMessage: "段落 \(segment.index + 1) 已导出")
        }
    }

    func export(record: GenerationRecord) {
        guard !record.audioPath.isEmpty else {
            statusMessage = "这条生成记录没有可导出的音频"
            return
        }
        let source = resolvedAudioURL(record.audioPath)
        guard FileManager.default.fileExists(atPath: source.path) else {
            statusMessage = "导出失败：音频文件不存在"
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.userAudioContentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = exportFileName(for: record)
        if panel.runModal() == .OK, let destination = panel.url {
            copyAudioFile(from: source, to: destination, successMessage: "生成记录已导出")
        }
    }

    func deleteGeneration(_ record: GenerationRecord, deleteFile: Bool = true) {
        do {
            try database?.deleteGeneration(id: record.id, workspaceRoot: paths.root.path, deleteFile: deleteFile)
            generationHistory.removeAll { $0.id == record.id }
            if fullGeneratedAudioPath == record.audioPath {
                fullGeneratedAudioPath = nil
            }
            if playingGenerationID == record.id {
                audioPlayer?.stop()
                playbackProgressTask?.cancel()
                playingGenerationID = nil
            }
            clearPausedPlaybackPoint(for: record.id)
            audioPlaybackProgress[record.id] = nil
            audioPlaybackDuration[record.id] = nil
            statusMessage = deleteFile ? "已删除生成记录和 workspace 内音频" : "已删除生成记录"
        } catch {
            statusMessage = "删除生成记录失败：\(error.localizedDescription)"
        }
    }

    func exportAllGenerated() {
        if let fullGeneratedAudioPath, FileManager.default.fileExists(atPath: fullGeneratedAudioPath) {
            presentFullAudioExportPanel(source: URL(fileURLWithPath: fullGeneratedAudioPath))
            return
        }

        mergeFullGeneratedAudio(exportAfterMerge: true)
    }

    func mergeFullGeneratedAudio(exportAfterMerge: Bool = false) {
        guard requireWorkspaceReady(action: "合成完整音频") else { return }
        guard !isGeneratingAllSegments else {
            statusMessage = "全文生成队列仍在运行，完成后再导出"
            return
        }
        guard !isMergingFullGeneratedAudio else {
            statusMessage = "完整音频正在合成"
            return
        }
        if let fullGeneratedAudioPath, FileManager.default.fileExists(atPath: fullGeneratedAudioPath) {
            if exportAfterMerge {
                presentFullAudioExportPanel(source: URL(fileURLWithPath: fullGeneratedAudioPath))
            }
            return
        }
        guard let mergeInput = currentFullAudioMergeInput() else {
            statusMessage = "当前段落还没有全部生成，无法合成完整音频"
            return
        }
        let workflow = selectedWorkflow
        let segmentCount = segments.count
        isMergingFullGeneratedAudio = true
        statusMessage = "正在合成完整音频，共 \(mergeInput.paths.count) 段"
        Task { [weak self] in
            var mergedPath: String?
            var mergeError: String?
            do {
                let response = try Self.performAudioConcat(input: mergeInput)
                mergedPath = Self.audioPath(fromConcatResponse: response)
            } catch {
                mergeError = error.localizedDescription
            }
            await MainActor.run {
                guard let self else { return }
                self.isMergingFullGeneratedAudio = false
                guard let mergedPath else {
                    self.statusMessage = "完整音频合成失败：\(mergeError ?? "后端没有返回音频路径")"
                    return
                }
                let absolutePath = self.resolvedAudioURL(mergedPath).path
                self.fullGeneratedAudioPath = absolutePath
                self.saveMergedFullGeneration(
                    audioPath: absolutePath,
                    workflow: workflow,
                    segmentCount: segmentCount,
                    gapSeconds: mergeInput.gapSeconds
                )
                self.refreshGenerationHistory()
                self.statusMessage = "已合成为完整 WebM"
                if exportAfterMerge {
                    self.presentFullAudioExportPanel(source: URL(fileURLWithPath: absolutePath))
                }
            }
        }
    }

    private func currentFullAudioMergeInput() -> FullAudioMergeInput? {
        let isMultiRoleMerge = selectedWorkflow == .multiRole
        let outputName = isMultiRoleMerge
            ? "\(Self.safeFileStem(projectTitle))-dialogue-full.webm"
            : "\(Self.safeFileStem(projectTitle))-full.webm"
        let orderedSegmentIDs = segments.map(\.id)
        let availableCount = orderedSegmentIDs.filter { segmentID in
            guard let path = generatedAudioPaths[segmentID] else { return false }
            return FileManager.default.fileExists(atPath: resolvedAudioURL(path).path)
        }.count
        let summary = GenerationQueueSummary(total: orderedSegmentIDs.count, succeeded: availableCount)
        guard let plan = GenerationQueueMergePlanner.plan(
            summary: summary,
            orderedSegmentIDs: orderedSegmentIDs,
            audioPathsBySegmentID: generatedAudioPaths,
            outputName: outputName,
            gapSeconds: isMultiRoleMerge ? Self.multiRoleConcatGapSeconds : 0
        ) else {
            return nil
        }
        return FullAudioMergeInput(
            backend: backend,
            paths: plan.paths,
            outputName: plan.outputName,
            gapSeconds: plan.gapSeconds
        )
    }

    private func presentFullAudioExportPanel(source: URL) {
        guard FileManager.default.fileExists(atPath: source.path) else {
            statusMessage = "导出失败：完整音频文件不存在"
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.userAudioContentType]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "\(Self.safeFileStem(projectTitle))-full.webm"
        if panel.runModal() == .OK, let destination = panel.url {
            copyAudioFile(from: source, to: destination, successMessage: "完整音频已导出")
        }
    }

    func chooseReferenceAudio() {
        guard requireWorkspaceReady(action: "导入参考音频") else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            importReferenceAudio(url: url)
        }
    }

    func importReferenceAudio(url: URL) {
        guard requireWorkspaceReady(action: "导入参考音频") else { return }
        Task { [weak self] in
            do {
                guard let self else { return }
                let response = try self.backend.oneShot(
                    method: "audio.import_reference",
                    params: ["path": url.path, "transcript": self.cloneReferenceText]
                )
                guard
                    let outer = response["result"] as? [String: Any],
                    let ok = outer["ok"] as? Bool,
                    ok,
                    let result = outer["result"] as? [String: Any],
                    let relativePath = result["path"] as? String
                else {
                    self.statusMessage = Self.errorMessage(from: response, fallback: "参考音频导入失败")
                    return
                }
                let duration = result["duration"] as? Double ?? 0
                let recording = ReferenceRecording(
                    id: result["id"] as? String ?? UUID().uuidString,
                    path: relativePath,
                    duration: duration,
                    transcript: self.cloneReferenceText,
                    consentID: result["consent_id"] as? String
                )
                _ = try self.database?.saveReferenceRecording(recording)
                self.cloneReferenceAudioPath = self.paths.root.appendingPathComponent(relativePath).path
                self.cloneReferenceDuration = duration > 0 ? duration : nil
                self.statusMessage = "参考音频已导入，时长 \(CloneVoiceWorkflowState(name: "", referenceAudioPath: relativePath, referenceText: "", purpose: "", duration: duration).durationText)"
            } catch {
                self?.statusMessage = "参考音频导入失败：\(error.localizedDescription)"
            }
        }
    }

    func startReferenceRecording() {
        guard requireWorkspaceReady(action: "录制参考音频") else { return }
        guard ensurePrivacyUsageDescriptions([.microphone], action: "录音") else { return }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            beginReferenceRecordingSession()
        case .notDetermined:
            statusMessage = "正在请求麦克风权限"
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.beginReferenceRecordingSession()
                    } else {
                        self.statusMessage = "录音不可用：未授权麦克风"
                    }
                }
            }
        case .denied, .restricted:
            statusMessage = "录音不可用：请在系统设置中允许 MacQwenVoice 使用麦克风"
        @unknown default:
            statusMessage = "录音不可用：麦克风权限状态未知"
        }
    }

    private func ensurePrivacyUsageDescriptions(
        _ capabilities: [PrivacyUsageDescriptions.Capability],
        action: String
    ) -> Bool {
        let missingKeys = PrivacyUsageDescriptions.missingKeys(
            for: capabilities,
            in: Bundle.main.infoDictionary
        )
        guard !missingKeys.isEmpty else { return true }
        statusMessage = "\(action)不可用：当前 App 缺少隐私用途说明 \(missingKeys.joined(separator: "、"))，请重新打包并从 Voice Studio.app 启动。"
        return false
    }

    private func beginReferenceRecordingSession() {
        do {
            let directory = paths.cache.appendingPathComponent("recordings", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("\(UUID().uuidString).wav")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: ReferenceRecordingFormatPolicy.safeRecorderSampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            guard audioRecorder?.record() == true else {
                audioRecorder = nil
                currentRecordingURL = nil
                isRecordingReference = false
                statusMessage = "录音启动失败：麦克风没有开始录制"
                return
            }
            currentRecordingURL = url
            isRecordingReference = true
            statusMessage = "正在录制参考音频"
        } catch {
            statusMessage = "录音启动失败：\(error.localizedDescription)"
        }
    }

    func stopReferenceRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecordingReference = false
        guard let currentRecordingURL else {
            statusMessage = "没有正在录制的参考音频"
            return
        }
        self.currentRecordingURL = nil
        statusMessage = "正在保存参考音频"
        Task { [weak self, currentRecordingURL] in
            let ready = await Self.waitUntilRecordingFileIsStable(at: currentRecordingURL)
            await MainActor.run {
                guard let self else { return }
                guard ready else {
                    self.statusMessage = "录音保存失败：参考音频文件未完成写入，请重新录制"
                    return
                }
                self.importReferenceAudio(url: currentRecordingURL)
            }
        }
    }

    func clearCloneReferenceAudio(deleteFile: Bool) {
        let path = cloneReferenceAudioPath
        if deleteFile, isWorkspacePath(path), FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        cloneReferenceAudioPath = ""
        cloneReferenceDuration = nil
        statusMessage = "已清空当前参考音频"
    }

    func saveClonedVoice(name: String) -> Bool {
        guard requireWorkspaceReady(action: "保存克隆音色") else { return false }
        let referenceAudioPath = cloneReferenceAudioPath
        let referenceText = cloneReferenceText
        let purpose = clonePurpose
        let workflowState = CloneVoiceWorkflowState(
            name: name,
            referenceAudioPath: referenceAudioPath,
            referenceText: referenceText,
            purpose: purpose,
            duration: cloneReferenceDuration
        )
        guard workflowState.canSave else {
            statusMessage = "克隆音色还缺：\(workflowState.missingRequirements.joined(separator: "、"))"
            return false
        }
        guard CustomVoiceNameAvailability.isAvailable(name, voices: voices) else {
            statusMessage = CustomVoiceNameAvailability.duplicateMessage
            return false
        }

        do {
            let response = try backend.oneShot(
                method: "consent.record",
                params: ["audio_source": referenceAudioPath, "purpose": purpose]
            )
            let result = response["result"] as? [String: Any]
            let consentID = result?["consent_id"] as? String ?? UUID().uuidString
            _ = try database?.saveConsent(ConsentRecord(id: consentID, audioSource: referenceAudioPath, purpose: purpose))

            let promptResponse = try backend.oneShot(
                method: "tts.create_voice_clone_prompt",
                params: [
                    "name": name,
                    "language": "Chinese",
                    "ref_audio": referenceAudioPath,
                    "ref_text": referenceText,
                    "consent_id": consentID
                ]
            )
            let promptResult = ((promptResponse["result"] as? [String: Any])?["result"] as? [String: Any])
            guard (((promptResponse["result"] as? [String: Any])?["ok"] as? Bool) == true) else {
                statusMessage = Self.errorMessage(from: promptResponse, fallback: "克隆音色 prompt 创建失败")
                return false
            }
            let clonePromptPath = promptResult?["clone_prompt_path"] as? String

            let voice = VoiceProfile(
                name: name,
                kind: .clonedVoice,
                language: "Chinese",
                instruct: "保持参考音色，自然清晰",
                referenceAudioPath: referenceAudioPath,
                referenceText: referenceText,
                consentID: consentID
            )
            _ = try database?.saveVoice(voice)
            _ = try database?.saveVoiceAsset(
                VoiceAsset(
                    id: voice.id,
                    type: .clonedVoice,
                    speaker: name,
                    language: "Chinese",
                    instruct: voice.instruct,
                    refAudioPath: referenceAudioPath,
                    refText: referenceText,
                    clonePromptPath: clonePromptPath,
                    consentID: consentID
                )
            )
            try refresh()
            selectVoice(voice)
            statusMessage = "克隆音色已保存，已设为当前音色"
            return true
        } catch {
            statusMessage = "克隆音色保存失败：\(error.localizedDescription)"
            return false
        }
    }

    func prepareCloneTestScript() {
        text = "这是一段用于测试克隆音色的短句，请确认它是否保持了参考音频里的音色、语气和清晰度。"
        instruct = "保持参考音色，自然清晰"
        updateSegments()
        statusMessage = "已载入克隆测试句，可直接生成试听"
    }

    func deleteVoice(_ voice: VoiceProfile, deleteFiles: Bool) {
        guard requireWorkspaceReady(action: "删除音色") else { return }
        guard voice.kind != .customVoice else {
            statusMessage = "内置精品音色不能删除"
            return
        }
        do {
            try database?.deleteVoice(id: voice.id, workspaceRoot: paths.root.path, deleteFiles: deleteFiles)
            try refresh()
            if selectedVoiceID == voice.id {
                selectVoiceSource(.builtin)
            }
            statusMessage = deleteFiles ? "已删除音色和 workspace 内关联文件" : "已删除音色记录"
        } catch {
            statusMessage = "删除音色失败：\(error.localizedDescription)"
        }
    }

    func renameVoice(_ voice: VoiceProfile, to newName: String) {
        guard requireWorkspaceReady(action: "重命名音色") else { return }
        guard voice.kind != .customVoice else {
            statusMessage = "内置精品音色不能重命名"
            return
        }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "音色名称不能为空"
            return
        }
        guard CustomVoiceNameAvailability.isAvailable(trimmed, voices: voices, excludingVoiceID: voice.id) else {
            statusMessage = "音色名称已存在，请换一个名称"
            return
        }
        do {
            try database?.renameVoice(id: voice.id, name: trimmed)
            try refresh()
            selectedVoiceID = voice.id
            statusMessage = "已重命名为 \(trimmed)"
        } catch {
            statusMessage = "重命名音色失败：\(error.localizedDescription)"
        }
    }

    func generateVoiceDesign(description: String, sampleText: String, language: String) {
        guard requireWorkspaceReady(action: "生成创造音色") else { return }
        guard !isGeneratingVoiceDesign else {
            statusMessage = "创造音色正在生成中"
            return
        }
        let synthesisText = SpeakerTaggedTextNormalizer.synthesisText(from: sampleText)
        guard !synthesisText.isEmpty else {
            statusMessage = "创造音色需要可朗读的合成文本，角色定义行不会送入 TTS"
            return
        }
        let modelID = catalog.models.first { $0.capability == .voiceDesign && $0.bundle == .advanced }?.id
            ?? "qwen3-tts-12hz-1.7b-voicedesign"
        selectedModelID = modelID
        let availability = modelAvailability(for: modelID)
        guard runtimeHealth.realInferenceAvailable else {
            statusMessage = "创造音色不可用：真实推理运行时未就绪"
            return
        }
        guard availability.available else {
            statusMessage = "创造音色不可用：\(availability.path)。请先下载或选择 1.7B VoiceDesign 模型。"
            return
        }
        voiceDesignPreviewPath = nil
        beginVoiceDesignProgress()
        Task { [weak self] in
            do {
                guard let self else { return }
                let response = try self.backend.oneShot(
                    method: "tts.generate_voice_design",
                    params: [
                        "text": synthesisText,
                        "language": language,
                        "model_id": modelID,
                        "voice": [:],
                        "instruct": description
                    ]
                )
                guard
                    let outer = response["result"] as? [String: Any],
                    let ok = outer["ok"] as? Bool,
                    ok,
                    let result = outer["result"] as? [String: Any],
                    let audioPath = result["audio_path"] as? String
                else {
                    self.finishVoiceDesignProgress(success: false)
                    self.statusMessage = Self.errorMessage(from: response, fallback: "创造音色失败")
                    return
                }
                self.voiceDesignPreviewPath = self.resolvedAudioURL(audioPath).path
                self.finishVoiceDesignProgress(success: true)
                self.statusMessage = "创造音色参考音已生成"
            } catch {
                self?.finishVoiceDesignProgress(success: false)
                self?.statusMessage = "创造音色失败：\(error.localizedDescription)"
            }
        }
    }

    func saveVoiceDesign(name: String, description: String, sampleText: String, language: String) {
        guard requireWorkspaceReady(action: "保存创造音色") else { return }
        guard let previewPath = voiceDesignPreviewPath, !previewPath.isEmpty else {
            statusMessage = "请先生成并试听参考声音，再保存角色音色"
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            statusMessage = "角色音色需要名称"
            return
        }
        guard CustomVoiceNameAvailability.isAvailable(trimmedName, voices: voices) else {
            statusMessage = CustomVoiceNameAvailability.duplicateMessage
            return
        }
        let synthesisText = SpeakerTaggedTextNormalizer.synthesisText(from: sampleText)
        guard !synthesisText.isEmpty else {
            statusMessage = "角色音色需要参考文本"
            return
        }
        let purpose = "VoiceDesign 生成的合成参考声音，用于本地角色音色复用"
        let voice = VoiceProfile(
            name: trimmedName,
            kind: .voiceDesign,
            language: language,
            speaker: trimmedName,
            instruct: "基于 VoiceDesign 角色设定复用：\(description)",
            referenceAudioPath: previewPath,
            referenceText: synthesisText
        )
        do {
            let response = try backend.oneShot(
                method: "consent.record",
                params: ["audio_source": previewPath, "purpose": purpose]
            )
            let result = response["result"] as? [String: Any]
            let consentID = result?["consent_id"] as? String ?? UUID().uuidString
            _ = try database?.saveConsent(ConsentRecord(id: consentID, audioSource: previewPath, purpose: purpose))

            let promptResponse = try backend.oneShot(
                method: "tts.create_voice_clone_prompt",
                params: [
                    "name": trimmedName,
                    "language": language,
                    "ref_audio": previewPath,
                    "ref_text": synthesisText,
                    "consent_id": consentID
                ]
            )
            let promptResult = ((promptResponse["result"] as? [String: Any])?["result"] as? [String: Any])
            guard (((promptResponse["result"] as? [String: Any])?["ok"] as? Bool) == true) else {
                statusMessage = Self.errorMessage(from: promptResponse, fallback: "创造音色 prompt 创建失败")
                return
            }
            let clonePromptPath = promptResult?["clone_prompt_path"] as? String

            let reusableVoice = VoiceProfile(
                id: voice.id,
                name: voice.name,
                kind: voice.kind,
                language: voice.language,
                speaker: trimmedName,
                instruct: voice.instruct,
                referenceAudioPath: previewPath,
                referenceText: synthesisText,
                consentID: consentID
            )
            _ = try database?.saveVoice(reusableVoice)
            _ = try database?.saveVoiceAsset(
                VoiceAsset(
                    id: reusableVoice.id,
                    type: reusableVoice.kind,
                    speaker: trimmedName,
                    language: language,
                    instruct: reusableVoice.instruct,
                    refAudioPath: previewPath,
                    refText: synthesisText,
                    clonePromptPath: clonePromptPath,
                    consentID: consentID
                )
            )
            try refresh()
            selectVoice(reusableVoice)
            statusMessage = "创造音色已保存，可在 Voice Studio 中复用"
        } catch {
            statusMessage = "创造音色保存失败：\(error.localizedDescription)"
        }
    }

    @discardableResult
    private func validateBoundMultiRoleVoices(for speakers: Set<String>) -> Bool {
        let normalizedSpeakers = Set(speakers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        guard !normalizedSpeakers.isEmpty else {
            statusMessage = "对话生成需要至少一个带角色标签的台词"
            return false
        }
        for speaker in normalizedSpeakers.sorted() {
            guard let boundVoice = manuallyBoundRoleVoice(for: speaker) else {
                let message = "角色 \(speaker) 未绑定音色，请在角色音色绑定里选择已保存的克隆音色或创造音色。"
                multiRoleVoicePreparationStatus[speaker] = .missing
                statusMessage = message
                return false
            }
            let missingRequirements = reusableRoleVoiceMissingRequirements(boundVoice)
            guard missingRequirements.isEmpty else {
                let message = "角色 \(speaker) 绑定的音色缺少 \(missingRequirements.joined(separator: "/"))，无法用于 Base 复用。"
                multiRoleVoicePreparationStatus[speaker] = .failed(message)
                statusMessage = message
                return false
            }
            multiRoleVoicePreparationStatus[speaker] = .ready
        }
        statusMessage = "对话角色音色已绑定并可用于 Base 复用"
        return true
    }

    func refreshDeepSeekConfiguration() {
        isDeepSeekConfigured = DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: try? deepSeekConfigStore.read())
        if isDeepSeekConfigured, deepSeekAPIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deepSeekAPIKeyInput = DeepSeekVoiceDescriptionRequest.savedKeyPlaceholder
        } else if !isDeepSeekConfigured, DeepSeekVoiceDescriptionRequest.isSavedKeyPlaceholder(deepSeekAPIKeyInput) {
            deepSeekAPIKeyInput = ""
        }
    }

    func saveDeepSeekAPIKeyFromInput() {
        let trimmed = deepSeekAPIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if trimmed.isEmpty {
                try deepSeekConfigStore.delete()
                statusMessage = "已清除本地 DeepSeek API key 配置"
            } else if DeepSeekVoiceDescriptionRequest.isSavedKeyPlaceholder(trimmed) {
                guard DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: try? deepSeekConfigStore.read()) else {
                    statusMessage = "请粘贴真实 DeepSeek API key 后再保存"
                    refreshDeepSeekConfiguration()
                    return
                }
                statusMessage = "DeepSeek API key 已保存"
            } else {
                try deepSeekConfigStore.save(trimmed)
                deepSeekAPIKeyInput = DeepSeekVoiceDescriptionRequest.savedKeyPlaceholder
                statusMessage = "DeepSeek API key 已保存到本地配置"
            }
            refreshDeepSeekConfiguration()
        } catch {
            statusMessage = "DeepSeek API key 保存失败：\(error.localizedDescription)"
        }
    }

    func pasteDeepSeekAPIKeyFromPasteboard() {
        let pasted = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !pasted.isEmpty else {
            statusMessage = "剪贴板里没有可用的 API key 文本"
            return
        }
        deepSeekAPIKeyInput = pasted
        statusMessage = "已从剪贴板填入 DeepSeek API key，请点击保存 Key"
    }

    func enhanceVoiceDescriptionWithDeepSeek(
        description: String,
        language: String,
        purpose: String,
        controlType: String = "VoiceDesign 角色音色卡",
        synthesisText: String = "",
        currentInstruction: String = "",
        apply: @escaping @MainActor (String) -> Void
    ) {
        let key = DeepSeekVoiceDescriptionRequest.resolvedAPIKey(apiKey: try? deepSeekConfigStore.read())
        guard let key else {
            statusMessage = "DeepSeek 未配置：请先填写 API key，或设置 DEEPSEEK_API_KEY"
            refreshDeepSeekConfiguration()
            return
        }
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            statusMessage = "请先填写基础声音描述"
            return
        }
        isEnhancingVoiceDescription = true
        statusMessage = "正在调用 DeepSeek 增强声音描述（会联网）"
        let requestBody = DeepSeekVoiceDescriptionRequest(
            description: trimmedDescription,
            language: language,
            purpose: purpose,
            controlType: controlType,
            synthesisText: synthesisText,
            currentInstruction: currentInstruction
        ).requestBody

        Task { [weak self] in
            do {
                var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    throw NSError(domain: "DeepSeek", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
                }
                let enhanced = try Self.deepSeekContent(from: data)
                await MainActor.run {
                    guard let self else { return }
                    apply(enhanced)
                    self.isEnhancingVoiceDescription = false
                    self.statusMessage = "DeepSeek 已生成控制指令"
                }
            } catch {
                await MainActor.run {
                    self?.isEnhancingVoiceDescription = false
                    self?.statusMessage = "DeepSeek 增强失败：\(error.localizedDescription)"
                }
            }
        }
    }

    func rewriteScriptWithDeepSeek(
        sourceText: String,
        contextSummary: String,
        stylePrompt: String,
        apply: @escaping @MainActor (DeepSeekScriptRewriteResult) -> Void
    ) {
        let key = DeepSeekVoiceDescriptionRequest.resolvedAPIKey(apiKey: try? deepSeekConfigStore.read())
        guard let key else {
            statusMessage = "DeepSeek 未配置：请先填写 API key，或设置 DEEPSEEK_API_KEY"
            refreshDeepSeekConfiguration()
            return
        }
        let trimmedSource = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSource.isEmpty else {
            statusMessage = "请先粘贴需要改写的小说或文本"
            return
        }
        isRewritingScriptWithDeepSeek = true
        statusMessage = "正在调用 DeepSeek 改写对话脚本（会联网）"
        let requestBody = DeepSeekScriptRewriteRequest(
            sourceText: trimmedSource,
            contextSummary: contextSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            stylePrompt: stylePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        ).requestBody

        Task { [weak self] in
            do {
                var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    throw NSError(domain: "DeepSeek", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
                }
                let content = try Self.deepSeekMessageContent(from: data)
                let result = try DeepSeekScriptRewriteResponse.parse(content: content)
                await MainActor.run {
                    guard let self else { return }
                    apply(result)
                    self.isRewritingScriptWithDeepSeek = false
                    self.statusMessage = "DeepSeek 已生成对话脚本"
                }
            } catch {
                await MainActor.run {
                    self?.isRewritingScriptWithDeepSeek = false
                    self?.statusMessage = "DeepSeek 对话改写失败：\(error.localizedDescription)"
                }
            }
        }
    }

    func applyScriptRewriteToScriptStudio(_ scriptText: String) {
        let trimmed = scriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "对话脚本为空，无法应用到 Script Studio"
            return
        }
        text = trimmed
        selectScriptStudioWorkflow(.multiRole)
        statusMessage = "已应用对话脚本，并切换到对话生成"
    }

    private var selectedVoice: VoiceProfile? {
        if let selectedVoiceID, let voice = voices.first(where: { $0.id == selectedVoiceID }) {
            return voice
        }
        switch selectedWorkflow {
        case .builtin:
            return builtinVoices.first
        case .custom:
            return customVoices.first
        case .voiceDesign, .multiRole:
            return nil
        }
    }

    private var currentReadyModelIDs: Set<String> {
        Set(modelStates.values.filter { $0.status == .ready }.map(\.id))
            .union(runtimeHealth.modelStatuses.filter { $0.exists }.map(\.id))
    }

    private func roleReusableVoiceName(for speaker: String) -> String {
        "\(reusableRoleVoiceNamePrefix)\(speaker.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private func bindSelectedDesignedVoiceToMatchingRoles(_ voice: VoiceProfile) {
        for roleName in SpeakerTaggedTextNormalizer.roleNames(from: text) where RoleVoiceBindingMatcher.matches(roleName: roleName, voice: voice) {
            multiRoleVoiceBindings[roleName] = voice.id
            multiRoleVoicePreparationStatus[roleName] = isUsableReusableRoleVoice(voice)
                ? .ready
                : .failed("绑定音色缺少 ref_audio/ref_text/consent")
        }
    }

    private func removeBindings(forVoiceID voiceID: String) {
        let boundRoles = multiRoleVoiceBindings.filter { $0.value == voiceID }.map(\.key)
        for roleName in boundRoles {
            multiRoleVoiceBindings.removeValue(forKey: roleName)
            multiRoleVoicePreparationStatus[roleName] = nil
        }
    }

    private func roleReusableVoice(for speaker: String) -> VoiceProfile? {
        manuallyBoundRoleVoice(for: speaker)
    }

    private func manuallyBoundRoleVoice(for speaker: String) -> VoiceProfile? {
        let normalizedSpeaker = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSpeaker.isEmpty else { return nil }
        guard let boundID = multiRoleVoiceBindings[normalizedSpeaker] else { return nil }
        return customVoices.first { $0.id == boundID }
    }

    private func multiRoleSourceKind(for voice: VoiceProfile, speaker: String) -> MultiRoleVoiceSourceKind {
        switch voice.kind {
        case .clonedVoice:
            return .clonedVoice
        case .voiceDesign:
            let normalizedSpeaker = speaker.trimmingCharacters(in: .whitespacesAndNewlines)
            return voice.name == roleReusableVoiceName(for: normalizedSpeaker) ? .generatedFromPrompt : .voiceDesign
        case .customVoice:
            return .unbound
        }
    }

    private func isUsableReusableRoleVoice(_ voice: VoiceProfile) -> Bool {
        reusableRoleVoiceMissingRequirements(voice).isEmpty
    }

    private func reusableRoleVoiceMissingRequirements(_ voice: VoiceProfile) -> [String] {
        let payload = voicePayload(for: voice).mapValues { String(describing: $0) }
        var missing: [String] = []
        if (payload["ref_audio"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("ref_audio")
        }
        if (payload["ref_text"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("ref_text")
        }
        if (payload["consent_id"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("consent")
        }
        return missing
    }

    private func displayLanguage(for language: String) -> String {
        switch language.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "chinese", "zh", "zh_cn", "zh-cn":
            return "中文"
        case "beijing_dialect", "beijing dialect":
            return "中文"
        case "sichuan_dialect", "sichuan dialect":
            return "中文"
        case "english", "en", "en_us", "en-us", "英语", "英文":
            return "英文"
        case "japanese", "ja", "日本語", "日语", "日文":
            return "日语"
        case "korean", "ko", "한국어", "韩语", "韩文":
            return "韩语"
        default:
            return language.isEmpty ? "中文" : language
        }
    }

    private func applyScriptStudioLanguageChoiceToControlProfile(_ choice: ScriptStudioLanguageChoice) {
        if choice.contains(.beijingDialect) {
            voiceControlProfile.language = "中文"
            voiceControlProfile.dialect = "北京话"
            return
        }
        if choice.contains(.sichuanDialect) {
            voiceControlProfile.language = "中文"
            voiceControlProfile.dialect = "四川话"
            return
        }
        if choice.contains(.chinese) {
            voiceControlProfile.language = "中文"
            if ["北京话", "四川话"].contains(voiceControlProfile.dialect) {
                voiceControlProfile.dialect = "普通话"
            }
            return
        }
        if choice.contains(.english) {
            voiceControlProfile.language = "英文"
            voiceControlProfile.dialect = ""
            return
        }
        if choice.contains(.japanese) {
            voiceControlProfile.language = "日语"
            voiceControlProfile.dialect = ""
            return
        }
        if choice.contains(.korean) {
            voiceControlProfile.language = "韩语"
            voiceControlProfile.dialect = ""
            return
        }
        applyVoiceLanguageToControlProfile(choice.requestLanguage(for: ""))
    }

    private func applyVoiceLanguageToControlProfile(_ language: String) {
        let displayLanguage = displayLanguage(for: language)
        voiceControlProfile.language = displayLanguage
        switch language.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "beijing_dialect", "beijing dialect":
            voiceControlProfile.dialect = "北京话"
            return
        case "sichuan_dialect", "sichuan dialect":
            voiceControlProfile.dialect = "四川话"
            return
        default:
            break
        }
        if displayLanguage != "中文", ["普通话", "北京话", "四川话"].contains(voiceControlProfile.dialect) {
            voiceControlProfile.dialect = ""
        }
    }

    private func normalizeScriptStudioControlsForSelectedWorkflow() {
        scriptStudioLanguageChoice = scriptStudioLanguageChoice.constrained(to: selectedWorkflow)
        guard selectedWorkflow != .builtin else { return }
        voiceControlProfile.dialect = ""
    }

    @discardableResult
    private func requireWorkspaceReady(action: String) -> Bool {
        guard workspaceReady, database != nil else {
            statusMessage = "请先初始化 workspace 后再\(action)"
            return false
        }
        return true
    }

    private func refresh() throws {
        voices = try database?.listVoices() ?? []
        voiceAssets = try database?.listVoiceAssets() ?? []
        if selectedVoiceID == nil || !voices.contains(where: { $0.id == selectedVoiceID }) {
            selectedVoiceID = voices.first?.id
        }
        selectedVoiceSource = VoiceSourceSelection.source(for: selectedVoice)
        selectedWorkflow = ScriptStudioWorkflow.normalizedAfterVoiceLibraryRefresh(
            current: selectedWorkflow,
            voiceSource: selectedVoiceSource
        )
        modelStates = Dictionary(uniqueKeysWithValues: (try database?.listModelStates() ?? []).map { ($0.id, $0) })
    }

    private func seedBuiltinVoices() throws {
        guard let database else { return }
        let existingVoices = try database.listVoices()
        if !existingVoices.isEmpty {
            if try database.listVoiceAssets().isEmpty {
                for voice in existingVoices {
                    _ = try database.saveVoiceAsset(
                        VoiceAsset(
                            id: voice.id,
                            type: voice.kind,
                            speaker: voice.speaker ?? voice.name,
                            language: voice.language,
                            instruct: voice.instruct,
                            refAudioPath: voice.referenceAudioPath,
                            refText: voice.referenceText,
                            consentID: voice.consentID
                        )
                    )
                }
            }
            return
        }
        for seed in Self.builtinVoiceSeeds {
            let voice = VoiceProfile(
                name: seed.0,
                kind: .customVoice,
                language: seed.1,
                speaker: seed.2,
                instruct: "\(seed.3)。默认风格：\(seed.4)"
            )
            _ = try database.saveVoice(voice)
            _ = try database.saveVoiceAsset(
                VoiceAsset(
                    id: voice.id,
                    type: .customVoice,
                    speaker: seed.2,
                    language: seed.1,
                    instruct: voice.instruct
                )
            )
        }
    }

    private static let builtinVoiceSeeds: [(String, String, String, String, String)] = [
        ("苏瑶 Serena", "Chinese", "Serena", "温暖、轻柔的年轻女声", "温柔、清晰、自然"),
        ("福伯 Uncle Fu", "Chinese", "Uncle_Fu", "成熟低沉男声", "低沉、稳重、叙事感"),
        ("十三 Vivian", "Chinese", "Vivian", "明亮、略带锋利的年轻女声", "明亮、有情绪变化"),
        ("艾登 Aiden", "English", "Aiden", "clear and friendly American male voice", "clear and friendly"),
        ("甜茶 Ryan", "English", "Ryan", "confident and rhythmic English male voice", "confident and rhythmic"),
        ("小野杏 Ono Anna", "Japanese", "Ono_Anna", "轻快灵动的日文女声", "playful and nimble"),
        ("素熙 Sohee", "Korean", "Sohee", "温暖有情绪的韩文女声", "warm and expressive"),
        ("晓东 Dylan", "Chinese", "Dylan", "自然清晰的北京男声", "清爽、自然、口语化"),
        ("程川 Eric", "Chinese", "Eric", "活泼的四川男声", "轻松、略带沙哑")
    ]

    private static func previewBuiltinVoices() -> [VoiceProfile] {
        builtinVoiceSeeds.map { seed in
            VoiceProfile(
                name: seed.0,
                kind: .customVoice,
                language: seed.1,
                speaker: seed.2,
                instruct: VoiceStudioDefaults.defaultBuiltinControlInstruction
            )
        }
    }

    private func finishDownload(_ spec: QwenModelSpec, localPath: String, result: DownloadResult) {
        do {
            downloadLogs[spec.id] = result.output
            if result.succeeded {
                _ = try? SpeechTokenizerStore.normalize(in: paths.models)
                try database?.saveModelState(ModelState(id: spec.id, localPath: localPath, status: .ready, bytes: folderSize(at: URL(fileURLWithPath: localPath))))
                statusMessage = "\(spec.displayName) 下载完成"
            } else {
                try database?.saveModelState(ModelState(id: spec.id, localPath: localPath, status: .failed, bytes: nil))
                statusMessage = "\(spec.displayName) 下载失败"
            }
            try refresh()
            refreshRuntimeHealth()
        } catch {
            statusMessage = "下载状态保存失败：\(error.localizedDescription)"
        }
    }

    private func reconcileReadyModelStates(from statuses: [RuntimeModelStatus]) {
        var changed = false
        let storedStates = persistedModelStatesByID()
        for status in statuses where status.exists {
            let current = modelStates[status.id]
            let stored = storedStates[status.id]
            guard ModelStateReconciliation.shouldPersistRuntimeReadyPath(
                current: current,
                stored: stored,
                runtimePath: status.localPath
            ) else {
                if let stored, modelStates[status.id] != stored {
                    modelStates[status.id] = stored
                }
                continue
            }
            if current?.status != .ready || current?.localPath != status.localPath {
                try? database?.saveModelState(
                    ModelState(
                        id: status.id,
                        localPath: status.localPath,
                        status: .ready,
                        bytes: folderSize(at: URL(fileURLWithPath: status.localPath))
                    )
                )
                changed = true
            }
        }
        if changed {
            try? refresh()
        }
    }

    private func mergePersistedModelStatesIntoMemory() {
        for (id, state) in persistedModelStatesByID() {
            guard
                let path = state.localPath?.trimmingCharacters(in: .whitespacesAndNewlines),
                !path.isEmpty
            else {
                continue
            }
            modelStates[id] = state
        }
    }

    private func persistedModelStatesByID() -> [String: ModelState] {
        guard let states = try? database?.listModelStates() else { return [:] }
        return Dictionary(uniqueKeysWithValues: states.map { ($0.id, $0) })
    }

    private func handleGenerationResponse(_ response: [String: Any], for segment: TextSegment, voice: VoiceProfile, modelID: String, prompt: String, recordMode: String? = nil) -> Bool {
        guard let outer = response["result"] as? [String: Any] else {
            finishGenerationProgress(for: segment.id, success: false)
            generationErrors[segment.id] = "后端返回不可识别"
            statusMessage = "生成失败：后端返回不可识别"
            return false
        }
        guard let ok = outer["ok"] as? Bool, ok else {
            let message = Self.errorMessage(from: response, fallback: "生成失败")
            finishGenerationProgress(for: segment.id, success: false)
            generationErrors[segment.id] = message
            statusMessage = message
            saveLocalGeneration(segment: segment, voice: voice, modelID: modelID, prompt: prompt, audioPath: "", runtime: "none", status: .failed, error: message, mode: recordMode)
            refreshGenerationHistory()
            return false
        }
        guard
            let result = outer["result"] as? [String: Any],
            let audioPath = result["audio_path"] as? String
        else {
            finishGenerationProgress(for: segment.id, success: false)
            generationErrors[segment.id] = "生成失败：缺少音频路径"
            statusMessage = "生成失败：缺少音频路径"
            return false
        }
        let absolutePath = resolvedAudioURL(audioPath).path
        let runtime = result["runtime"] as? String ?? "unknown"
        generatedAudioPaths[segment.id] = absolutePath
        generatedModelIDs[segment.id] = modelID
        generatedVoiceNames[segment.id] = voice.name
        generatedInstructions[segment.id] = prompt
        generatedRuntimes[segment.id] = runtime
        saveLocalGeneration(segment: segment, voice: voice, modelID: modelID, prompt: prompt, audioPath: absolutePath, runtime: runtime, status: .ready, error: nil, mode: recordMode)
        refreshGenerationHistory()
        finishGenerationProgress(for: segment.id, success: true)
        statusMessage = "段落 \(segment.index + 1) 已生成"
        return true
    }

    private func handleGenerationFailure(_ error: Error, for segment: TextSegment) {
        finishGenerationProgress(for: segment.id, success: false)
        generationErrors[segment.id] = error.localizedDescription
        statusMessage = "生成失败：\(error.localizedDescription)"
    }

    private func beginGenerationProgress(for segment: TextSegment) {
        generatingSegmentIDs.insert(segment.id)
        generationProgress[segment.id] = 0.04
        generationProgressLabel[segment.id] = "启动后端"
        progressTasks[segment.id]?.cancel()
        progressTasks[segment.id] = Task { [weak self] in
            let start = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let state = Self.estimatedProgress(elapsedSeconds: elapsed)
                self?.generationProgress[segment.id] = state.value
                self?.generationProgressLabel[segment.id] = state.label
                self?.statusMessage = "段落 \(segment.index + 1)：\(state.label)"
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
    }

    private func finishGenerationProgress(for segmentID: String, success: Bool) {
        progressTasks[segmentID]?.cancel()
        progressTasks[segmentID] = nil
        generationProgress[segmentID] = success ? 1.0 : 0.0
        generationProgressLabel[segmentID] = success ? "完成" : "失败"
        generatingSegmentIDs.remove(segmentID)
    }

    private static func estimatedProgress(elapsedSeconds: TimeInterval) -> (value: Double, label: String) {
        let stage = GenerationProgressEstimator.estimatedTTSProgress(elapsedSeconds: elapsedSeconds)
        return (stage.value, stage.label)
    }

    private func beginVoiceDesignProgress() {
        isGeneratingVoiceDesign = true
        voiceDesignProgress = 0.04
        voiceDesignProgressLabel = "启动后端"
        voiceDesignProgressTask?.cancel()
        voiceDesignProgressTask = Task { [weak self] in
            let start = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let estimate = GenerationProgressEstimator.estimatedTTSProgress(elapsedSeconds: elapsed)
                self?.voiceDesignProgress = estimate.value
                self?.voiceDesignProgressLabel = estimate.label
                self?.statusMessage = "创造音色：\(estimate.label)"
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
        }
    }

    private func finishVoiceDesignProgress(success: Bool) {
        voiceDesignProgressTask?.cancel()
        voiceDesignProgressTask = nil
        isGeneratingVoiceDesign = false
        voiceDesignProgress = success ? 1.0 : 0.0
        voiceDesignProgressLabel = success ? "完成" : "失败"
    }

    private func preferredRoleVoiceDesignModelID() -> String {
        let readyModelIDs = currentReadyModelIDs
        return catalog.preferredModelID(
            for: .voiceDesign,
            selectedModelID: selectedModelID,
            readyModelIDs: readyModelIDs
        )
    }

    private func ensureRoleLiveVoiceDesignAvailable() -> Bool {
        guard catalog.voiceDesignModels.first != nil else {
            statusMessage = "多角色现场生成不可用：缺少 VoiceDesign 模型定义"
            return false
        }
        let modelID = preferredRoleVoiceDesignModelID()
        let availability = modelAvailability(for: modelID)
        guard availability.available else {
            statusMessage = "多角色现场生成不可用：\(availability.path)。请先下载或选择 1.7B VoiceDesign 模型。"
            return false
        }
        return true
    }

    private func saveLocalGeneration(
        segment: TextSegment,
        voice: VoiceProfile,
        modelID: String,
        prompt: String,
        audioPath: String,
        runtime: String,
        status: GenerationStatus,
        error: String?,
        mode: String? = nil
    ) {
        try? database?.saveGeneration(
            GenerationRecord(
                mode: mode?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? mode! : voice.kind.rawValue,
                modelID: modelID,
                voiceAssetID: voice.id,
                text: segment.text,
                instruct: prompt,
                audioPath: audioPath,
                runtime: runtime,
                status: status,
                error: error
            )
        )
    }

    private func saveMergedFullGeneration(
        audioPath: String,
        workflow: ScriptStudioWorkflow,
        segmentCount: Int,
        gapSeconds: Double
    ) {
        let isMultiRole = workflow == .multiRole
        let text = isMultiRole
            ? "完整对话音频（\(segmentCount) 段）"
            : "完整合成音频（\(segmentCount) 段）"
        let instruction = isMultiRole
            ? "Base 逐句复用角色音色，合并时每段之间插入约 \(Self.compactSecondsLabel(gapSeconds)) 秒静音。"
            : "按段落顺序合并完整音频。"
        try? database?.saveGeneration(
            GenerationRecord(
                mode: isMultiRole ? "multi_role_full" : "full_audio",
                modelID: "audio.concat_audio",
                voiceAssetID: nil,
                text: text,
                instruct: instruction,
                audioPath: audioPath,
                runtime: "webm-concat",
                status: .ready,
                error: nil
            )
        )
    }

    private static func compactSecondsLabel(_ seconds: Double) -> String {
        let roundedTenths = (seconds * 10).rounded() / 10
        if roundedTenths == roundedTenths.rounded() {
            return String(format: "%.0f", roundedTenths)
        }
        return String(format: "%.1f", roundedTenths)
    }

    private func modelID(for voice: VoiceProfile) -> String {
        let capability = capability(for: voice)
        return catalog.preferredModelID(
            for: capability,
            selectedModelID: selectedModelID,
            readyModelIDs: currentReadyModelIDs
        )
    }

    private func capability(for voice: VoiceProfile) -> ModelCapability {
        switch voice.kind {
        case .clonedVoice:
            return .voiceClone
        case .voiceDesign:
            return .voiceClone
        case .customVoice:
            return .customVoice
        }
    }

    private func workflow(for voice: VoiceProfile) -> ScriptStudioWorkflow {
        switch voice.kind {
        case .customVoice:
            return .builtin
        case .clonedVoice, .voiceDesign:
            return .custom
        }
    }

    private func chainLabel(for voice: VoiceProfile) -> String {
        switch voice.kind {
        case .customVoice:
            return "精品音色"
        case .clonedVoice:
            return "克隆音色"
        case .voiceDesign:
            return "创造音色"
        }
    }

    private func method(for voice: VoiceProfile) -> String {
        switch voice.kind {
        case .customVoice:
            "tts.generate_custom_voice"
        case .clonedVoice:
            "tts.generate_voice_clone"
        case .voiceDesign:
            "tts.generate_voice_clone"
        }
    }

    private func voicePayload(for voice: VoiceProfile) -> [String: Any] {
        let asset = voiceAssets.first { $0.id == voice.id }
        let payload: [String: Any] = [
            "speaker": voice.speaker ?? "",
            "ref_audio": asset?.refAudioPath ?? voice.referenceAudioPath ?? "",
            "ref_text": asset?.refText ?? voice.referenceText ?? "",
            "reference_audio": asset?.refAudioPath ?? voice.referenceAudioPath ?? "",
            "reference_text": asset?.refText ?? voice.referenceText ?? "",
            "clone_prompt_path": asset?.clonePromptPath ?? "",
            "consent_id": asset?.consentID ?? voice.consentID ?? ""
        ]
        return payload.filter { !String(describing: $0.value).isEmpty }
    }

    private func speakerInput(for voice: VoiceProfile?) -> String {
        guard let voice else { return "" }
        return (voice.speaker ?? voice.name).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func referenceInput(for voice: VoiceProfile?) -> (audio: String, text: String) {
        guard let voice else { return ("", "") }
        let asset = voiceAssets.first { $0.id == voice.id }
        let defaultText = (asset?.refText ?? voice.referenceText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return (
            (asset?.refAudioPath ?? voice.referenceAudioPath ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            defaultText
        )
    }

    private func resolvedAudioURL(_ path: String) -> URL {
        let url = URL(fileURLWithPath: path)
        if path.hasPrefix("/") {
            return url
        }
        return paths.root.appendingPathComponent(path)
    }

    private func isWorkspacePath(_ path: String) -> Bool {
        guard !path.isEmpty else { return false }
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let standardizedRoot = paths.root.standardizedFileURL.path
        return standardizedPath == standardizedRoot || standardizedPath.hasPrefix("\(standardizedRoot)/")
    }

    private func exportFileName(for segment: TextSegment) -> String {
        let title = Self.safeFileStem(projectTitle)
        return "\(title)-段落\(segment.index + 1).webm"
    }

    private func exportFileName(for record: GenerationRecord) -> String {
        let title = Self.safeFileStem(projectTitle)
        let timestamp = Int(record.createdAt.timeIntervalSince1970)
        return "\(title)-生成\(timestamp).webm"
    }

    private static func webMFileName(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "audio.webm" }
        if trimmed.lowercased().hasSuffix(".webm") {
            return trimmed
        }
        let url = URL(fileURLWithPath: trimmed)
        if url.pathExtension.isEmpty {
            return "\(trimmed).webm"
        }
        return "\(url.deletingPathExtension().lastPathComponent).webm"
    }

    private static func safeFileStem(_ value: String) -> String {
        let safe = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return safe.isEmpty ? VoiceStudioDefaults.appDisplayName : safe
    }

    private func copyAudioFile(from source: URL, to destination: URL, successMessage: String) {
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            statusMessage = successMessage
        } catch {
            statusMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func folderSize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    private static func errorMessage(from response: [String: Any], fallback: String) -> String {
        guard
            let outer = response["result"] as? [String: Any],
            let error = outer["error"] as? [String: Any]
        else {
            return fallback
        }
        let code = error["code"] as? String ?? "ERROR"
        let message = error["message"] as? String ?? fallback
        return "\(code)：\(message)"
    }

    private static func generationAudioPath(from response: [String: Any]) -> String? {
        guard
            let outer = response["result"] as? [String: Any],
            let ok = outer["ok"] as? Bool,
            ok,
            let result = outer["result"] as? [String: Any],
            let audioPath = result["audio_path"] as? String,
            !audioPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return audioPath
    }

    private static func clonePromptPath(from response: [String: Any]) -> String? {
        guard
            let outer = response["result"] as? [String: Any],
            let ok = outer["ok"] as? Bool,
            ok,
            let result = outer["result"] as? [String: Any],
            let clonePromptPath = result["clone_prompt_path"] as? String,
            !clonePromptPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return clonePromptPath
    }

    private static func deepSeekMessageContent(from data: Data) throws -> String {
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = object["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw NSError(domain: "DeepSeek", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应中没有可用描述"])
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw NSError(domain: "DeepSeek", code: -2, userInfo: [NSLocalizedDescriptionKey: "增强结果为空"])
        }
        return trimmed
    }

    private static func deepSeekContent(from data: Data) throws -> String {
        DeepSeekVoiceDescriptionResponse.preferredInstruction(from: try deepSeekMessageContent(from: data))
    }

    private static func generationRecord(from row: [String: Any]) -> GenerationRecord? {
        guard
            let id = row["id"] as? String,
            let mode = row["mode"] as? String,
            let modelID = row["model_id"] as? String,
            let text = row["text"] as? String
        else { return nil }
        return GenerationRecord(
            id: id,
            mode: mode,
            modelID: modelID,
            voiceAssetID: row["voice_asset_id"] as? String,
            text: text,
            instruct: row["instruct"] as? String ?? "",
            audioPath: row["audio_path"] as? String ?? "",
            runtime: row["runtime"] as? String ?? "",
            status: GenerationStatus(rawValue: row["status"] as? String ?? "") ?? .failed,
            error: row["error"] as? String,
            createdAt: Date(timeIntervalSince1970: row["created_at"] as? Double ?? Date().timeIntervalSince1970)
        )
    }

    nonisolated private static func performGenerationCall(input: GenerationCallInput, backend: BackendJSONClient) throws -> [String: Any] {
        var params: [String: Any] = [
            "text": input.text,
            "language": input.language,
            "model_id": input.modelID,
            "voice_asset_id": input.voiceAssetID,
            "voice": input.voice,
            "instruct": input.instruct
        ]
        if let modelPath = input.modelPath, !modelPath.isEmpty {
            params["model_path"] = modelPath
        }
        if !input.route.isEmpty {
            params["route"] = input.route
        }
        if let seed = input.seed {
            params["seed"] = seed
        }
        return try backend.request(method: input.method, params: params)
    }

    nonisolated private static func performAudioConcat(input: FullAudioMergeInput) throws -> [String: Any] {
        try input.backend.request(
            method: "audio.concat_audio",
            params: [
                "paths": input.paths,
                "name": input.outputName,
                "gap_seconds": input.gapSeconds
            ]
        )
    }

    nonisolated private static func audioPath(fromConcatResponse response: [String: Any]) -> String? {
        guard
            let outer = response["result"] as? [String: Any],
            let ok = outer["ok"] as? Bool,
            ok,
            let result = outer["result"] as? [String: Any],
            let audioPath = result["audio_path"] as? String
        else {
            return nil
        }
        return audioPath
    }

    nonisolated private static func runDownload(plan: HuggingFaceDownloadPlan) -> DownloadResult {
        var selectedPlan = plan
        var logs: [String] = []

        let dryRun = runHF(arguments: plan.dryRunArguments, environment: plan.processEnvironment)
        logs.append("dry-run via \(plan.displayName)\n\(dryRun.output)")
        if dryRun.status != 0 {
            if plan.normalizedEndpoint == HuggingFaceDownloadPlan.mirrorEndpoint {
                let fallback = plan.fallbackToOfficial()
                let officialDryRun = runHF(arguments: fallback.dryRunArguments, environment: fallback.processEnvironment)
                logs.append("mirror dry-run failed; fallback dry-run via \(fallback.displayName)\n\(officialDryRun.output)")
                guard officialDryRun.status == 0 else {
                    return DownloadResult(succeeded: false, output: logs.joined(separator: "\n\n"))
                }
                selectedPlan = fallback
            } else {
                return DownloadResult(succeeded: false, output: logs.joined(separator: "\n\n"))
            }
        }

        let download = runHF(arguments: selectedPlan.downloadArguments, environment: selectedPlan.processEnvironment)
        logs.append("download via \(selectedPlan.displayName)\n\(download.output)")
        return DownloadResult(succeeded: download.status == 0, output: logs.joined(separator: "\n\n"))
    }

    nonisolated private static func runHF(arguments: [String], environment processEnvironment: [String: String]) -> (status: Int32, output: String) {
        let process = Process()
        let hfExecutable = VoiceStudioRuntimeEnvironment.executableURL(named: "hf")
        process.executableURL = hfExecutable ?? URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = hfExecutable == nil ? ["hf"] + arguments : arguments
        process.environment = VoiceStudioRuntimeEnvironment.mergedEnvironment(extra: processEnvironment)
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        do {
            try process.run()
            process.waitUntilExit()
            let log = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return (process.terminationStatus, log)
        } catch {
            return (-1, error.localizedDescription)
        }
    }

    nonisolated private static func runRuntimeInstaller(
        scriptURL: URL,
        onOutput: @escaping @Sendable (String) async -> Void
    ) async -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        process.environment = VoiceStudioRuntimeEnvironment.mergedEnvironment()
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        do {
            try process.run()
            var log = ""
            while true {
                let data = output.fileHandleForReading.availableData
                if data.isEmpty {
                    break
                }
                let text = String(data: data, encoding: .utf8) ?? ""
                log += text
                await onOutput(text)
            }
            process.waitUntilExit()
            return (process.terminationStatus, log)
        } catch {
            return (-1, error.localizedDescription)
        }
    }
}

private struct GenerationCallInput: Sendable {
    let method: String
    let route: String
    let text: String
    let language: String
    let modelID: String
    let modelPath: String?
    let voiceAssetID: String
    let voice: [String: String]
    let instruct: String
    let seed: Int?
}

private struct PreparedGenerationContext: Sendable {
    let callInput: GenerationCallInput
    let backend: BackendJSONClient
    let segment: TextSegment
    let voice: VoiceProfile
    let modelID: String
    let recordMode: String
}

private struct FullAudioMergeInput: Sendable {
    let backend: BackendJSONClient
    let paths: [String]
    let outputName: String
    let gapSeconds: Double
}

struct RuntimeHealthViewState: Equatable {
    var runtime: String
    var realInferenceAvailable: Bool
    var dependencies: [String: Bool]
    var optionalDependencies: [String: Bool]
    var hardware: [String: String]
    var runtimeSummary: String
    var modelStatuses: [RuntimeModelStatus]
    var message: String

    static let unknown = RuntimeHealthViewState(
        runtime: "unknown",
        realInferenceAvailable: false,
        dependencies: [:],
        optionalDependencies: [:],
        hardware: [:],
        runtimeSummary: "",
        modelStatuses: [],
        message: "正在检查运行时"
    )

    static func unavailable(message: String) -> RuntimeHealthViewState {
        RuntimeHealthViewState(
            runtime: "unavailable",
            realInferenceAvailable: false,
            dependencies: [:],
            optionalDependencies: [:],
            hardware: [:],
            runtimeSummary: "",
            modelStatuses: [],
            message: message
        )
    }

    init(payload: [String: Any]) {
        runtime = payload["runtime"] as? String ?? "unknown"
        realInferenceAvailable = payload["real_inference_available"] as? Bool ?? false
        dependencies = payload["dependencies"] as? [String: Bool] ?? [:]
        optionalDependencies = payload["optional_dependencies"] as? [String: Bool] ?? [:]
        hardware = (payload["hardware"] as? [String: Any] ?? [:]).mapValues { String(describing: $0) }
        runtimeSummary = payload["runtime_summary"] as? String ?? ""
        let rows = payload["models"] as? [[String: Any]] ?? []
        modelStatuses = rows.compactMap(RuntimeModelStatus.init(payload:))
        let suffix = runtimeSummary.isEmpty ? "" : "；\(runtimeSummary)"
        message = realInferenceAvailable ? "真实 Qwen3-TTS 推理可用\(suffix)" : "真实推理不可用：请安装 mlx-audio / mlx，或检查 Python 环境\(suffix)"
    }

    private init(
        runtime: String,
        realInferenceAvailable: Bool,
        dependencies: [String: Bool],
        optionalDependencies: [String: Bool],
        hardware: [String: String],
        runtimeSummary: String,
        modelStatuses: [RuntimeModelStatus],
        message: String
    ) {
        self.runtime = runtime
        self.realInferenceAvailable = realInferenceAvailable
        self.dependencies = dependencies
        self.optionalDependencies = optionalDependencies
        self.hardware = hardware
        self.runtimeSummary = runtimeSummary
        self.modelStatuses = modelStatuses
        self.message = message
    }
}

struct RuntimeModelStatus: Equatable, Identifiable {
    let id: String
    let repository: String
    let localPath: String
    let exists: Bool
    let variant: String
    let capability: String

    init?(payload: [String: Any]) {
        guard let id = payload["id"] as? String else { return nil }
        self.id = id
        repository = payload["repository"] as? String ?? ""
        localPath = payload["local_path"] as? String ?? ""
        exists = payload["exists"] as? Bool ?? false
        variant = payload["variant"] as? String ?? ""
        capability = payload["capability"] as? String ?? ""
    }
}

struct ModelAvailabilityViewState: Equatable {
    let modelID: String
    let available: Bool
    let path: String
    let label: String
}

private struct DownloadResult: Sendable {
    let succeeded: Bool
    let output: String
}
