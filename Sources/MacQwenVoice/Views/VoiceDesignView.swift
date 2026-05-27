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
        VoiceDesignLanguageOption(title: "Chinese", value: "Chinese"),
        VoiceDesignLanguageOption(title: "English", value: "English"),
        VoiceDesignLanguageOption(title: "Japanese", value: "Japanese"),
        VoiceDesignLanguageOption(title: "Korean", value: "Korean"),
        VoiceDesignLanguageOption(title: "German", value: "German"),
        VoiceDesignLanguageOption(title: "French", value: "French"),
        VoiceDesignLanguageOption(title: "Russian", value: "Russian"),
        VoiceDesignLanguageOption(title: "Portuguese", value: "Portuguese"),
        VoiceDesignLanguageOption(title: "Spanish", value: "Spanish"),
        VoiceDesignLanguageOption(title: "Italian", value: "Italian")
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
            viewModel.localized(.designDeleteTitle),
            isPresented: Binding(
                get: { voicePendingDeletion != nil },
                set: { if !$0 { voicePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let voice = voicePendingDeletion {
                Button(viewModel.localized(.cloneDeleteRecordOnly), role: .destructive) {
                    viewModel.deleteVoice(voice, deleteFiles: false)
                    voicePendingDeletion = nil
                }
                Button(viewModel.localized(.cloneDeleteRecordAndFiles), role: .destructive) {
                    viewModel.deleteVoice(voice, deleteFiles: true)
                    voicePendingDeletion = nil
                }
            }
            Button(viewModel.localized(.commonCancel), role: .cancel) {
                voicePendingDeletion = nil
            }
        } message: {
            Text(viewModel.localized(.cloneDeleteMessage))
        }
    }

    private func modelPanel(modelID: String, availability: ModelAvailabilityViewState) -> some View {
        StudioPanel {
            HStack {
                StudioSectionHeader(viewModel.localized(.pageVoiceDesignModelTitle), subtitle: viewModel.localized(.pageVoiceDesignModelSubtitle))
                Spacer()
                Label(availability.label, systemImage: availability.available ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(availability.available ? StudioTheme.success : StudioTheme.warning)
                if let model = viewModel.catalog.models.first(where: { $0.id == modelID }) {
                    Button {
                        viewModel.downloadModel(model)
                    } label: {
                        Label(availability.available ? viewModel.localized(.modelInstalled) : viewModel.localized(.modelDownload), systemImage: availability.available ? "checkmark.circle.fill" : "arrow.down.circle")
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
                    StudioSectionHeader(viewModel.localized(.pageVoiceDesignInputTitle), subtitle: viewModel.localized(.pageVoiceDesignInputSubtitle))
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.localized(.designLanguage))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Picker(viewModel.localized(.designLanguage), selection: $viewModel.voiceDesignPageDraft.language) {
                            ForEach(Self.languageOptions) { option in
                                Text(option.title(language: viewModel.effectiveAppLanguage)).tag(option.value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 130, alignment: .leading)
                    }
                }
                multilineEditor(
                    title: viewModel.localized(.designInstructionTitle),
                    subtitle: viewModel.localized(.designInstructionSubtitle),
                    text: $viewModel.voiceDesignPageDraft.controlInstruction,
                    minHeight: 132
                )
                multilineEditor(
                    title: viewModel.localized(.designSynthesisTitle),
                    subtitle: viewModel.localized(.designSynthesisSubtitle),
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
                        Label(viewModel.isGeneratingVoiceDesign ? viewModel.localized(.designGenerating) : viewModel.localized(.designGenerateReferenceVoice), systemImage: "sparkles")
                    }
                    .disabled(!canGenerate || viewModel.isGeneratingVoiceDesign)
                    AudioPlayButton(
                        viewModel.localized(.designPlayReferenceVoice),
                        pauseTitle: viewModel.localized(.designPauseReferenceVoice),
                        item: viewModel.voiceDesignPreviewPath.map { AudioPlaybackItem.file(path: $0, context: "voice-design-preview") }
                    )
                    Button {
                        saveVoiceName = ""
                        isSaveVoiceSheetPresented = true
                    } label: {
                        Label(viewModel.localized(.designSaveAsVoice), systemImage: "bookmark")
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
                StudioSectionHeader(viewModel.localized(.designEnhanceControlTitle), subtitle: viewModel.localized(.designEnhanceControlSubtitle))
                deepSeekStatusPanel
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        StudioSectionHeader(viewModel.localized(.scriptVoiceControlTitle), subtitle: viewModel.localized(.designControlTypeSubtitle))
                        Spacer()
                        Button {
                            viewModel.voiceDesignPageDraft.isControlExpanded.toggle()
                        } label: {
                            Label(
                                viewModel.voiceDesignPageDraft.isControlExpanded ? viewModel.localized(.scriptCollapse) : viewModel.localized(.scriptExpand),
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
                        Label(viewModel.localized(.designGenerateInitialInstruction), systemImage: "text.insert")
                    }
                    Button {
                        applyGeneratedControlInstruction()
                    } label: {
                        Label(viewModel.localized(.designApplyInitialInstruction), systemImage: "arrow.up.circle")
                    }
                    .disabled(viewModel.voiceDesignPageDraft.generatedControlInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
                .buttonStyle(.bordered)
                multilineEditor(
                    title: viewModel.localized(.designInitialInstructionTitle),
                    subtitle: viewModel.localized(.designInitialInstructionSubtitle),
                    text: $viewModel.voiceDesignPageDraft.generatedControlInstruction,
                    minHeight: 96
                )
                HStack {
                    Button {
                        enhanceCurrentControlInstructionWithDeepSeek()
                    } label: {
                        Label(viewModel.isEnhancingVoiceDescription ? viewModel.localized(.designEnhancing) : viewModel.localized(.designUseDeepSeekEnhance), systemImage: "wand.and.stars")
                    }
                    .disabled(!viewModel.isDeepSeekConfigured || viewModel.isEnhancingVoiceDescription)
                    Button {
                        applyDeepSeekEnhancedInstruction()
                    } label: {
                        Label(viewModel.localized(.designApplyEnhancedInstruction), systemImage: "arrow.up.circle.fill")
                    }
                    .disabled(viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
                .buttonStyle(.bordered)
                multilineEditor(
                    title: viewModel.localized(.designDeepSeekInstructionTitle),
                    subtitle: viewModel.localized(.designDeepSeekInstructionSubtitle),
                    text: $viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction,
                    minHeight: 112
                )
            }
        }
    }

    private var deepSeekStatusPanel: some View {
        HStack(alignment: .center, spacing: 10) {
            Label(
                viewModel.isDeepSeekConfigured ? viewModel.localized(.settingsDeepSeekConfigured) : viewModel.localized(.settingsDeepSeekUnconfigured),
                systemImage: viewModel.isDeepSeekConfigured ? "checkmark.circle.fill" : "circle"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(viewModel.isDeepSeekConfigured ? StudioTheme.success : .secondary)
            Text(viewModel.isDeepSeekConfigured
                 ? viewModel.localized(.designDeepSeekConfiguredHint)
                 : viewModel.localized(.designDeepSeekMissingHint))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                onOpenSettings()
            } label: {
                Label(viewModel.localized(.commonOpenSettings), systemImage: "gearshape")
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
                Label(viewModel.localized(.designGenerationProgress), systemImage: viewModel.isGeneratingVoiceDesign ? "waveform" : "timer")
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
                StudioSectionHeader(viewModel.localized(.designSavedTitle), subtitle: viewModel.localized(.designSavedSubtitle))
                let designVoices = viewModel.voices.filter { $0.kind == .voiceDesign }
                if designVoices.isEmpty {
                    Text(viewModel.localized(.designEmptySaved))
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
                                    viewModel.localized(.designPreviewReference),
                                    pauseTitle: viewModel.localized(.designPausePreviewReference),
                                    item: voice.referenceAudioPath
                                        .map { AudioPlaybackItem.file(path: $0, context: "voice-design-saved-\(voice.id)") }
                                )
                                .disabled((voice.referenceAudioPath ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                Button {
                                    viewModel.selectVoice(voice)
                                    onOpenScriptStudio()
                                } label: {
                                    Label(viewModel.localized(.cloneUseForGeneration), systemImage: "arrow.right.circle")
                                }
                                Button {
                                    voicePendingRename = voice
                                    renameVoiceName = voice.name
                                } label: {
                                    Label(viewModel.localized(.cloneRename), systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    voicePendingDeletion = voice
                                } label: {
                                    Label(viewModel.localized(.commonDelete), systemImage: "trash")
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
            Text(viewModel.localized(.designSaveRoleTitle))
                .font(.headline)
            Text(viewModel.localized(.designSaveRoleSubtitle))
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(viewModel.localized(.designSaveNamePlaceholder), text: $saveVoiceName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitSaveVoiceIfPossible(validation)
                }
            if let message = localizedValidationMessage(validation) {
                Label(message, systemImage: validation == .available ? "checkmark.circle" : "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(validation == .available ? StudioTheme.success : StudioTheme.warning)
            }
            HStack {
                Spacer()
                Button(viewModel.localized(.commonCancel)) {
                    isSaveVoiceSheetPresented = false
                }
                Button(viewModel.localized(.commonSave)) {
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
            Text(viewModel.localized(.designRenameTitle))
                .font(.headline)
            TextField(viewModel.localized(.cloneRenamePlaceholder), text: $renameVoiceName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitRename()
                }
            HStack {
                Spacer()
                Button(viewModel.localized(.commonCancel)) {
                    voicePendingRename = nil
                }
                Button(viewModel.localized(.commonSave)) {
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
        viewModel.statusMessage = viewModel.localized(.designStatusAppliedInitial)
    }

    private func applyDeepSeekEnhancedInstruction() {
        let instruction = viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty else { return }
        viewModel.voiceDesignPageDraft.controlInstruction = instruction
        viewModel.statusMessage = viewModel.localized(.designStatusAppliedEnhanced)
    }

    private func enhanceCurrentControlInstructionWithDeepSeek() {
        let source = enhancementInstructionSource
        guard !source.isEmpty else {
            viewModel.statusMessage = viewModel.localized(.designStatusNeedInstruction)
            return
        }
        viewModel.enhanceVoiceDescriptionWithDeepSeek(
            description: source,
            language: viewModel.voiceDesignPageDraft.language,
            purpose: viewModel.localized(.designDeepSeekPurpose),
            controlType: viewModel.localized(.designDeepSeekControlType),
            synthesisText: viewModel.voiceDesignPageDraft.synthesisText,
            currentInstruction: source
        ) { enhanced in
            viewModel.voiceDesignPageDraft.deepSeekEnhancedInstruction = enhanced
        }
    }

    private func localizedValidationMessage(_ validation: VoiceDesignSaveNameValidationState) -> String? {
        switch validation {
        case .empty:
            viewModel.localized(.designNameEmpty)
        case .duplicate:
            viewModel.localized(.designNameDuplicate)
        case .available:
            nil
        }
    }
}

private struct VoiceDesignControlPanel: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    @Binding var controlInstruction: String

    private var interfaceLanguage: AppLanguage { viewModel.effectiveAppLanguage }

    private var definitions: [VoiceControlAttributeDefinition] {
        VoiceControlAttributeCatalog.definitions(for: .voiceDesign, language: interfaceLanguage)
    }

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 220), spacing: 10, alignment: .topLeading)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StudioSectionHeader(viewModel.localized(.scriptVoiceControlTitle), subtitle: viewModel.localized(.designControlTypeSubtitle))
                Spacer()
                Button {
                    viewModel.randomizeVoiceControlProfile(for: .voiceDesign)
                    controlInstruction = viewModel.compiledVoiceDesignPrompt
                } label: {
                    Label(viewModel.localized(.scriptRandomGenerate), systemImage: "dice")
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
                                Text(preset.title(language: interfaceLanguage))
                                    .font(.caption.weight(.semibold))
                                Text(preset.category.title(language: interfaceLanguage))
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
                Picker(viewModel.localized(.scriptChooseAttributeFormat, definition.title), selection: candidateSelection(text: text, candidates: candidates)) {
                    Text(viewModel.localized(.scriptNotSpecified)).tag("")
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
        VoiceControlAttributeCatalog.candidates(for: definition.id, workflow: .voiceDesign, language: interfaceLanguage)
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
                    Text(option.isEmpty ? (emptyTitle ?? viewModel.localized(.scriptNotSpecified)) : option).tag(option)
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

    func title(language: AppLanguage) -> String {
        switch value {
        case "Chinese":
            return ScriptStudioLanguageOption.chinese.displayTitle(language: language)
        case "English":
            return ScriptStudioLanguageOption.english.displayTitle(language: language)
        case "Japanese":
            return ScriptStudioLanguageOption.japanese.displayTitle(language: language)
        case "Korean":
            return ScriptStudioLanguageOption.korean.displayTitle(language: language)
        case "German":
            return ScriptStudioLanguageOption.german.displayTitle(language: language)
        case "French":
            return ScriptStudioLanguageOption.french.displayTitle(language: language)
        case "Russian":
            return ScriptStudioLanguageOption.russian.displayTitle(language: language)
        case "Portuguese":
            return ScriptStudioLanguageOption.portuguese.displayTitle(language: language)
        case "Spanish":
            return ScriptStudioLanguageOption.spanish.displayTitle(language: language)
        case "Italian":
            return ScriptStudioLanguageOption.italian.displayTitle(language: language)
        default:
            return title
        }
    }
}
