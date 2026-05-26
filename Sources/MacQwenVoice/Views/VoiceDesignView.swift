import MacQwenVoiceCore
import SwiftUI

struct VoiceDesignView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenScriptStudio: () -> Void
    let onOpenSettings: () -> Void
    @State private var isSaveVoiceSheetPresented = false
    @State private var saveVoiceName = ""
    @State private var voicePendingDeletion: VoiceProfile?
    @State private var voicePendingRename: VoiceProfile?
    @State private var renameVoiceName = ""
    private static let languageOptions: [VoiceDesignLanguageOption] = [
        VoiceDesignLanguageOption(title: "中文", value: "Chinese"),
        VoiceDesignLanguageOption(title: "英文", value: "English"),
        VoiceDesignLanguageOption(title: "日语", value: "Japanese"),
        VoiceDesignLanguageOption(title: "韩语", value: "Korean"),
        VoiceDesignLanguageOption(title: "德语", value: "German"),
        VoiceDesignLanguageOption(title: "法语", value: "French"),
        VoiceDesignLanguageOption(title: "俄语", value: "Russian"),
        VoiceDesignLanguageOption(title: "葡萄牙语", value: "Portuguese"),
        VoiceDesignLanguageOption(title: "西班牙语", value: "Spanish"),
        VoiceDesignLanguageOption(title: "意大利语", value: "Italian")
    ]

    var body: some View {
        let modelID = viewModel.catalog.models.first { $0.capability == .voiceDesign && $0.bundle == .advanced }?.id
            ?? "qwen3-tts-12hz-1.7b-voicedesign"
        let availability = viewModel.modelAvailability(for: modelID)
        let canGenerate = viewModel.runtimeHealth.realInferenceAvailable && availability.available

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                modelPanel(modelID: modelID, availability: availability)
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 16) {
                        primaryVoiceDesignPanel(canGenerate: canGenerate)
                        enhancementPanel
                    }
                    .frame(minWidth: 560)
                    savedVoicesPanel
                        .frame(minWidth: 420)
                }
            }
            .padding(StudioTheme.pagePadding)
        }
        .onAppear {
            viewModel.refreshDeepSeekConfiguration()
        }
        .sheet(
            isPresented: $isSaveVoiceSheetPresented
        ) {
            saveVoiceSheet
        }
        .sheet(
            isPresented: Binding(
                get: { voicePendingRename != nil },
                set: { if !$0 { voicePendingRename = nil } }
            )
        ) {
            renameSheet
        }
        .confirmationDialog(
            "删除创造音色？",
            isPresented: Binding(
                get: { voicePendingDeletion != nil },
                set: { if !$0 { voicePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let voice = voicePendingDeletion {
                Button("仅删除音色记录", role: .destructive) {
                    viewModel.deleteVoice(voice, deleteFiles: false)
                    voicePendingDeletion = nil
                }
                Button("删除记录并删除关联文件", role: .destructive) {
                    viewModel.deleteVoice(voice, deleteFiles: true)
                    voicePendingDeletion = nil
                }
            }
            Button("取消", role: .cancel) {
                voicePendingDeletion = nil
            }
        } message: {
            Text("删除文件只会处理 Voice Studio workspace 内的参考音频和 clone prompt。")
        }
    }

    private func modelPanel(modelID: String, availability: ModelAvailabilityViewState) -> some View {
        StudioPanel {
            HStack {
                StudioSectionHeader("VoiceDesign 模型", subtitle: "自然语言声音创造使用 1.7B VoiceDesign。")
                Spacer()
                Label(availability.label, systemImage: availability.available ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(availability.available ? StudioTheme.success : StudioTheme.warning)
                if let model = viewModel.catalog.models.first(where: { $0.id == modelID }) {
                    Button {
                        viewModel.downloadModel(model)
                    } label: {
                        Label(availability.available ? "已安装" : "下载", systemImage: availability.available ? "checkmark.circle.fill" : "arrow.down.circle")
                    }
                    .disabled(availability.available)
                }
            }
            Text(availability.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private func primaryVoiceDesignPanel(canGenerate: Bool) -> some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    StudioSectionHeader("VoiceDesign 主输入", subtitle: "这里的 language、指令控制和合成文本会直接送入 1.7B VoiceDesign。")
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("语言")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Picker("语言", selection: $viewModel.voiceDesignPageDraft.language) {
                            ForEach(Self.languageOptions) { option in
                                Text(option.title).tag(option.value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 130, alignment: .leading)
                    }
                }
                multilineEditor(
                    title: "指令控制",
                    subtitle: "直接作为 VoiceDesign 的 instruct/prompt 送入模型。",
                    text: $viewModel.voiceDesignPageDraft.controlInstruction,
                    minHeight: 132
                )
                multilineEditor(
                    title: "合成文本 / 试听文本",
                    subtitle: "模型要朗读的正文内容；保存角色音色时会作为这次参考声音的文本。",
                    text: $viewModel.voiceDesignPageDraft.synthesisText,
                    minHeight: 92
                )
                voiceDesignProgressPanel
                HStack {
                    Button {
                        viewModel.generateVoiceDesign(
                            description: viewModel.voiceDesignPageDraft.controlInstruction,
                            sampleText: viewModel.voiceDesignPageDraft.synthesisText,
                            language: viewModel.voiceDesignPageDraft.language
                        )
                    } label: {
                        Label(viewModel.isGeneratingVoiceDesign ? "生成中" : "生成参考声音", systemImage: "sparkles")
                    }
                    .disabled(!canGenerate || viewModel.isGeneratingVoiceDesign)
                    AudioPlayButton(
                        "播放参考声音",
                        pauseTitle: "暂停参考声音",
                        item: viewModel.voiceDesignPreviewPath.map { AudioPlaybackItem.file(path: $0, context: "voice-design-preview") }
                    )
                    Button {
                        saveVoiceName = ""
                        isSaveVoiceSheetPresented = true
                    } label: {
                        Label("保存为音色", systemImage: "bookmark")
                    }
                    .disabled(viewModel.voiceDesignPreviewPath == nil)
                    Spacer()
                }
                if viewModel.voiceDesignPreviewPath != nil {
                    Text(viewModel.audioDurationLabel(path: viewModel.voiceDesignPreviewPath))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var enhancementPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader("增强控制指令", subtitle: "控制类型和 DeepSeek 都只生成候选指令；点击应用后才会写回上方指令控制。")
                deepSeekStatusPanel
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        StudioSectionHeader("控制类型", subtitle: "展开后可选择并编辑 VoiceDesign 控制属性。")
                        Spacer()
                        Button {
                            viewModel.voiceDesignPageDraft.isControlExpanded.toggle()
                        } label: {
                            Label(
                                viewModel.voiceDesignPageDraft.isControlExpanded ? "收起" : "展开",
                                systemImage: viewModel.voiceDesignPageDraft.isControlExpanded ? "chevron.up" : "slider.horizontal.3"
                            )
                        }
                        .controlSize(.small)
                    }
                    if viewModel.voiceDesignPageDraft.isControlExpanded {
                        VoiceDesignControlPanel(controlInstruction: $viewModel.voiceDesignPageDraft.generatedControlInstruction)
                    }
                }
                .padding(10)
                .background(StudioTheme.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                HStack {
                    Button {
                        viewModel.voiceDesignPageDraft.generatedControlInstruction = viewModel.compiledVoiceDesignPrompt
                    } label: {
                        Label("生成初始控制指令", systemImage: "text.insert")
                    }
                    Button {
                        applyGeneratedControlInstruction()
                    } label: {
                        Label("应用初始指令", systemImage: "arrow.up.circle")
                    }
                    .disabled(viewModel.voiceDesignPageDraft.generatedControlInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
                .buttonStyle(.bordered)
                multilineEditor(
                    title: "初始控制指令",
                    subtitle: "由控制类型组合生成，可手动编辑；不会自动影响上方主输入。",
                    text: $viewModel.voiceDesignPageDraft.generatedControlInstruction,
                    minHeight: 96
                )
                HStack {
                    Button {
                        enhanceCurrentControlInstructionWithDeepSeek()
                    } label: {
                        Label(viewModel.isEnhancingVoiceDescription ? "增强中" : "使用 DeepSeek 增强", systemImage: "wand.and.stars")
                    }
                    .disabled(!viewModel.isDeepSeekConfigured || viewModel.isEnhancingVoiceDescription)
                    Button {
                        applyDeepSeekEnhancedInstruction()
                    } label: {
                        Label("应用增强指令", systemImage: "arrow.up.circle.fill")
                    }
                    .disabled(viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
                .buttonStyle(.bordered)
                multilineEditor(
                    title: "DeepSeek 增强指令",
                    subtitle: "DeepSeek 的联网增强输出会显示在这里，确认后再应用到上方指令控制。",
                    text: $viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction,
                    minHeight: 112
                )
            }
        }
    }

    private var deepSeekStatusPanel: some View {
        HStack(alignment: .center, spacing: 10) {
            Label(
                viewModel.isDeepSeekConfigured ? "DeepSeek 已配置" : "DeepSeek 未配置",
                systemImage: viewModel.isDeepSeekConfigured ? "checkmark.circle.fill" : "circle"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(viewModel.isDeepSeekConfigured ? StudioTheme.success : .secondary)
            Text(viewModel.isDeepSeekConfigured
                 ? "可使用联网增强生成候选控制指令。"
                 : "在“设置”里配置 API key 后可使用联网增强。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                onOpenSettings()
            } label: {
                Label("打开设置", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var voiceDesignProgressPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("生成进度", systemImage: viewModel.isGeneratingVoiceDesign ? "waveform" : "timer")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int((viewModel.voiceDesignProgress * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: viewModel.voiceDesignProgress, total: 1)
                .progressViewStyle(.linear)
            Text(viewModel.voiceDesignProgressLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func multilineEditor(
        title: String,
        subtitle: String,
        text: Binding<String>,
        minHeight: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: minHeight)
                .background(StudioTheme.workspaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                        .stroke(StudioTheme.border, lineWidth: 1)
                }
        }
    }

    private var savedVoicesPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 10) {
                StudioSectionHeader("已保存创造音色", subtitle: "管理、重命名、删除或发送到 Voice Studio 使用。")
                let designVoices = viewModel.voices.filter { $0.kind == .voiceDesign }
                if designVoices.isEmpty {
                    Text("还没有保存的创造音色。生成参考声音并保存后会显示在这里。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .studioCardStyle()
                } else {
                    ForEach(designVoices) { voice in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(voice.name)
                                        .font(.headline)
                                    Text(voice.instruct)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            HStack {
                                AudioPlayButton(
                                    "试听参考音",
                                    pauseTitle: "暂停参考音",
                                    item: voice.referenceAudioPath
                                        .map { AudioPlaybackItem.file(path: $0, context: "voice-design-saved-\(voice.id)") }
                                )
                                .disabled((voice.referenceAudioPath ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                Button {
                                    viewModel.selectVoice(voice)
                                    onOpenScriptStudio()
                                } label: {
                                    Label("用于生成", systemImage: "arrow.right.circle")
                                }
                                Button {
                                    voicePendingRename = voice
                                    renameVoiceName = voice.name
                                } label: {
                                    Label("重命名", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    voicePendingDeletion = voice
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .studioCardStyle()
                    }
                }
            }
        }
    }

    private var saveVoiceSheet: some View {
        let validation = VoiceDesignSaveNameValidation.state(for: saveVoiceName, voices: viewModel.voices)
        return VStack(alignment: .leading, spacing: 14) {
            Text("保存为角色音色")
                .font(.headline)
            Text("这里的名称会写入已保存创造音色列表，并绑定当前参考声音与试听文本。")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("输入要保存的音色名称", text: $saveVoiceName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitSaveVoiceIfPossible(validation)
                }
            if let message = validation.message {
                Label(message, systemImage: validation == .available ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(validation == .available ? StudioTheme.success : StudioTheme.warning)
            }
            HStack {
                Spacer()
                Button("取消") {
                    isSaveVoiceSheetPresented = false
                }
                Button("保存") {
                    submitSaveVoiceIfPossible(validation)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!validation.canSave)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private var renameSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("重命名创造音色")
                .font(.headline)
            TextField("新的音色名称", text: $renameVoiceName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitRename()
                }
            HStack {
                Spacer()
                Button("取消") {
                    voicePendingRename = nil
                }
                Button("保存") {
                    submitRename()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renameVoiceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private func submitRename() {
        guard let voice = voicePendingRename else { return }
        viewModel.renameVoice(voice, to: renameVoiceName)
        voicePendingRename = nil
    }

    private func submitSaveVoiceIfPossible(_ validation: VoiceDesignSaveNameValidationState) {
        guard validation.canSave else { return }
        viewModel.saveVoiceDesign(
            name: saveVoiceName,
            description: viewModel.voiceDesignPageDraft.controlInstruction,
            sampleText: viewModel.voiceDesignPageDraft.synthesisText,
            language: viewModel.voiceDesignPageDraft.language
        )
        isSaveVoiceSheetPresented = false
        saveVoiceName = ""
    }

    private var enhancementInstructionSource: String {
        let generated = viewModel.voiceDesignPageDraft.generatedControlInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        if !generated.isEmpty {
            return generated
        }
        return viewModel.voiceDesignPageDraft.controlInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func applyGeneratedControlInstruction() {
        let instruction = viewModel.voiceDesignPageDraft.generatedControlInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty else { return }
        viewModel.voiceDesignPageDraft.controlInstruction = instruction
        viewModel.statusMessage = "已将初始控制指令应用到上方主输入"
    }

    private func applyDeepSeekEnhancedInstruction() {
        let instruction = viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty else { return }
        viewModel.voiceDesignPageDraft.controlInstruction = instruction
        viewModel.statusMessage = "已将 DeepSeek 增强指令应用到上方主输入"
    }

    private func enhanceCurrentControlInstructionWithDeepSeek() {
        let source = enhancementInstructionSource
        guard !source.isEmpty else {
            viewModel.statusMessage = "请先填写上方指令控制，或生成初始控制指令"
            return
        }
        viewModel.enhanceVoiceDescriptionWithDeepSeek(
            description: source,
            language: viewModel.voiceDesignPageDraft.language,
            purpose: "VoiceDesign 声音创造",
            controlType: "VoiceDesign 控制指令增强",
            synthesisText: viewModel.voiceDesignPageDraft.synthesisText,
            currentInstruction: source
        ) { enhanced in
            viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction = enhanced
        }
    }
}

private struct VoiceDesignControlPanel: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    @Binding var controlInstruction: String

    private var definitions: [VoiceControlAttributeDefinition] {
        VoiceControlAttributeCatalog.definitions(for: .voiceDesign)
    }

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 220), spacing: 10, alignment: .topLeading)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StudioSectionHeader("控制类型", subtitle: "可选择并编辑 VoiceDesign 控制维度。")
                Spacer()
                Button {
                    viewModel.randomizeVoiceControlProfile(for: .voiceDesign)
                    controlInstruction = viewModel.compiledVoiceDesignPrompt
                } label: {
                    Label("随机生成", systemImage: "dice")
                }
                .controlSize(.small)
                StudioPill(title: "VoiceDesign", systemImage: "sparkles", color: .purple)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VoiceControlPreset.recommendedForVoiceDesign) { preset in
                        Button {
                            viewModel.applyVoiceControlPreset(preset)
                            controlInstruction = viewModel.compiledVoiceDesignPrompt
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(.caption.weight(.semibold))
                                Text(preset.category.title)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.bottom, 1)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(definitions) { definition in
                    attributeField(definition)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private func attributeField(_ definition: VoiceControlAttributeDefinition) -> some View {
        let text = binding(for: definition.id)
        let candidates = candidates(for: definition)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(definition.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("选择\(definition.title)", selection: candidateSelection(text: text, candidates: candidates)) {
                    Text("不指定").tag("")
                    ForEach(candidates, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 96)
            }
            TextField(definition.title, text: text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func candidateSelection(text: Binding<String>, candidates: [String]) -> Binding<String> {
        Binding(
            get: { candidates.contains(text.wrappedValue) ? text.wrappedValue : "" },
            set: { if !$0.isEmpty { text.wrappedValue = $0 } }
        )
    }

    private func candidates(for definition: VoiceControlAttributeDefinition) -> [String] {
        VoiceControlAttributeCatalog.candidates(for: definition.id, workflow: .voiceDesign)
    }

    private func binding(for id: VoiceControlAttributeID) -> Binding<String> {
        switch id {
        case .roleName: $viewModel.voiceControlProfile.roleName
        case .language: $viewModel.voiceControlProfile.language
        case .dialect: $viewModel.voiceControlProfile.dialect
        case .age: $viewModel.voiceControlProfile.age
        case .genderPresentation: $viewModel.voiceControlProfile.genderPresentation
        case .pitch: $viewModel.voiceControlProfile.pitch
        case .speed: $viewModel.voiceControlProfile.speed
        case .volume: $viewModel.voiceControlProfile.volume
        case .clarity: $viewModel.voiceControlProfile.clarity
        case .fluency: $viewModel.voiceControlProfile.fluency
        case .accent: $viewModel.voiceControlProfile.accent
        case .emotion: $viewModel.voiceControlProfile.emotion
        case .tone: $viewModel.voiceControlProfile.tone
        case .persona: $viewModel.voiceControlProfile.persona
        case .acousticTexture: $viewModel.voiceControlProfile.acousticTexture
        case .humanLikeness: $viewModel.voiceControlProfile.humanLikeness
        case .background: $viewModel.voiceControlProfile.background
        case .gradient: $viewModel.voiceControlProfile.gradient
        case .negativePrompt: $viewModel.voiceControlProfile.negativePrompt
        case .customPrompt: $viewModel.voiceControlProfile.customPrompt
        }
    }

    private func menuPicker(
        _ title: String,
        selection: Binding<String>,
        options: [String],
        emptyTitle: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.isEmpty ? (emptyTitle ?? "默认") : option).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func controlTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
        }
    }
}

private struct VoiceDesignLanguageOption: Identifiable {
    let title: String
    let value: String

    var id: String { value }
}
