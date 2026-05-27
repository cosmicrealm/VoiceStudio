import MacQwenVoiceCore
import SwiftUI

struct ClonedVoicesView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenScriptStudio: () -> Void
    @State private var voicePendingDeletion: VoiceProfile?
    @State private var voicePendingRename: VoiceProfile?
    @State private var renameVoiceName = ""
    @State private var isShowingSaveSheet = false

    private var workflowState: CloneVoiceWorkflowState {
        CloneVoiceWorkflowState(
            name: viewModel.clonedVoicesPageDraft.cloneName,
            referenceAudioPath: viewModel.cloneReferenceAudioPath,
            referenceText: viewModel.cloneReferenceText,
            purpose: viewModel.clonePurpose,
            duration: viewModel.cloneReferenceDuration
        )
    }

    private var hasReferenceInput: Bool {
        !viewModel.cloneReferenceAudioPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.cloneReferenceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var transcriptExampleColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 240), spacing: 8, alignment: .top)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 16) {
                        transcriptPanel
                        referenceAudioPanel
                        transcriptExamplesPanel
                    }
                    .frame(minWidth: 520)
                    savedVoicesPanel
                        .frame(minWidth: 420)
                }
            }
            .padding(StudioTheme.pagePadding)
        }
        .sheet(
            isPresented: Binding(
                get: { voicePendingRename != nil },
                set: { if !$0 { voicePendingRename = nil } }
            )
        ) {
            renameSheet
        }
        .sheet(isPresented: $isShowingSaveSheet) {
            saveCloneSheet
        }
        .confirmationDialog(
            viewModel.localized(.cloneDeleteTitle),
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

    private var pageHeader: some View {
        StudioPanel {
            HStack {
                StudioSectionHeader(viewModel.localized(.pageClonedTitle), subtitle: viewModel.localized(.pageClonedSubtitle))
                Spacer()
                StudioPill(title: viewModel.localized(.cloneCountFormat, "\(viewModel.voices.filter { $0.kind == .clonedVoice }.count)"), systemImage: "waveform.badge.mic", color: Color.accentColor)
            }
        }
    }

    private var transcriptPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader(viewModel.localized(.cloneTranscriptTitle), subtitle: viewModel.localized(.cloneTranscriptSubtitle))
                TextField(viewModel.localized(.cloneTranscriptPlaceholder), text: $viewModel.cloneReferenceText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                HStack {
                    Button {
                        viewModel.fillCloneTranscriptFromCurrentScript()
                    } label: {
                        Label(viewModel.localized(.cloneFillFromScript), systemImage: "text.quote")
                    }
                    Button {
                        viewModel.clearCloneTranscript()
                    } label: {
                        Label(viewModel.localized(.commonClear), systemImage: "xmark.circle")
                    }
                    .disabled(viewModel.cloneReferenceText.isEmpty)
                    Spacer()
                }
            }
        }
    }

    private var transcriptExamplesPanel: some View {
        StudioPanel {
            DisclosureGroup(isExpanded: $viewModel.clonedVoicesPageDraft.isTranscriptExamplesExpanded) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(LocalizedDefaultContent.defaults(for: viewModel.appLanguage).cloneReferenceExamples, id: \.language) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(group.language)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: transcriptExampleColumns, alignment: .leading, spacing: 8) {
                                ForEach(group.examples, id: \.self) { example in
                                    transcriptExampleButton(example)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    StudioSectionHeader(viewModel.localized(.cloneTranscriptExamplesTitle), subtitle: viewModel.localized(.cloneTranscriptExamplesSubtitle))
                    Spacer()
                    StudioPill(
                        title: viewModel.localized(.cloneExamplesCountFormat, "\(LocalizedDefaultContent.defaults(for: viewModel.appLanguage).cloneReferenceExamples.reduce(0) { $0 + $1.examples.count })"),
                        systemImage: "text.quote",
                        color: Color.accentColor
                    )
                }
            }
        }
    }

    private var referenceAudioPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader(viewModel.localized(.cloneReferenceAudioTitle), subtitle: viewModel.localized(.cloneReferenceAudioSubtitle))
                HStack {
                    Button {
                        viewModel.chooseReferenceAudio()
                    } label: {
                        Label(viewModel.localized(.cloneImportAudio), systemImage: "folder")
                    }
                    Button {
                        viewModel.isRecordingReference ? viewModel.stopReferenceRecording() : viewModel.startReferenceRecording()
                    } label: {
                        Label(viewModel.isRecordingReference ? viewModel.localized(.cloneStopRecording) : viewModel.localized(.cloneRecordAudio), systemImage: viewModel.isRecordingReference ? "stop.circle" : "mic.circle")
                    }
                    AudioPlayButton(
                        viewModel.localized(.clonePlayReference),
                        pauseTitle: viewModel.localized(.clonePauseReference),
                        item: viewModel.cloneReferenceAudioPath.isEmpty
                            ? nil
                            : AudioPlaybackItem.file(path: viewModel.cloneReferenceAudioPath, context: "clone-reference")
                    )
                    Button(role: .destructive) {
                        viewModel.clearCloneReferenceAudio(deleteFile: true)
                    } label: {
                        Label(viewModel.localized(.cloneDeleteReferenceAudio), systemImage: "trash")
                    }
                    .disabled(viewModel.cloneReferenceAudioPath.isEmpty)
                }
                HStack {
                    Button {
                        isShowingSaveSheet = true
                    } label: {
                        Label(viewModel.localized(.cloneSaveAsVoice), systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasReferenceInput)
                    StudioPill(
                        title: hasReferenceInput ? viewModel.localized(.cloneCanSave) : viewModel.localized(.cloneMissingFormat, referenceInputMissingText),
                        systemImage: hasReferenceInput ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                        color: hasReferenceInput ? StudioTheme.success : StudioTheme.warning
                    )
                    Spacer()
                }
                TextField(viewModel.localized(.cloneReferenceAudioPath), text: $viewModel.cloneReferenceAudioPath)
                    .textFieldStyle(.roundedBorder)
                    .textSelection(.enabled)
                HStack {
                    StudioPill(
                        title: workflowState.referenceAudioPath.isEmpty ? viewModel.localized(.cloneReferenceAudioMissing) : viewModel.localized(.cloneReferenceAudioReady),
                        systemImage: workflowState.referenceAudioPath.isEmpty ? "exclamationmark.triangle" : "checkmark.circle.fill",
                        color: workflowState.referenceAudioPath.isEmpty ? StudioTheme.warning : StudioTheme.success
                    )
                    Text(viewModel.localized(.cloneDurationFormat, workflowState.durationText))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    private var savedVoicesPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader(viewModel.localized(.cloneSavedTitle), subtitle: viewModel.localized(.cloneSavedSubtitle))
                let clonedVoices = viewModel.voices.filter { $0.kind == .clonedVoice }
                if clonedVoices.isEmpty {
                    Text(viewModel.localized(.cloneEmptySaved))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .studioCardStyle()
                } else {
                    ForEach(clonedVoices) { voice in
                        savedVoiceRow(voice)
                    }
                }
            }
        }
    }

    private func savedVoiceRow(_ voice: VoiceProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.name)
                        .font(.headline)
                    Text(voice.referenceAudioPath ?? viewModel.localized(.cloneMissingRecordedAudio))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        viewModel.selectVoice(voice)
                        onOpenScriptStudio()
                    } label: {
                        Label(viewModel.localized(.cloneUseForGeneration), systemImage: "arrow.right.circle")
                    }
                    Button {
                        viewModel.selectVoice(voice)
                        viewModel.prepareCloneTestScript()
                        onOpenScriptStudio()
                    } label: {
                        Label(viewModel.localized(.cloneGenerateTestSentence), systemImage: "text.badge.checkmark")
                    }
                    Spacer()
                }
                HStack {
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
                    Spacer()
                }
            }
            .buttonStyle(.bordered)
        }
        .studioCardStyle()
    }

    private var referenceInputMissingText: String {
        var missing: [String] = []
        if viewModel.cloneReferenceAudioPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(viewModel.localized(.cloneReferenceAudioRequirement))
        }
        if viewModel.cloneReferenceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(viewModel.localized(.cloneReferenceTranscriptRequirement))
        }
        return missing.joined(separator: ", ")
    }

    private func transcriptExampleButton(_ example: String) -> some View {
        Button {
            viewModel.cloneReferenceText = example
            viewModel.statusMessage = viewModel.localized(.cloneTranscriptExampleApplied)
        } label: {
            Text(example)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(StudioTheme.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                        .stroke(StudioTheme.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var saveCloneSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.localized(.cloneSaveAsVoice))
                .font(.headline)
            Text(viewModel.localized(.cloneSaveSheetSubtitle))
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(viewModel.localized(.cloneVoiceNamePlaceholder), text: $viewModel.clonedVoicesPageDraft.cloneName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitSaveClone()
                }
            TextField(viewModel.localized(.clonePurposePlaceholder), text: $viewModel.clonePurpose, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            StudioPill(
                title: workflowState.canSave ? viewModel.localized(.cloneCanSaveSheet) : viewModel.localized(.cloneMissingFormat, localizedMissingRequirements.joined(separator: ", ")),
                systemImage: workflowState.canSave ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                color: workflowState.canSave ? StudioTheme.success : StudioTheme.warning
            )
            HStack {
                Spacer()
                Button(viewModel.localized(.commonCancel)) {
                    isShowingSaveSheet = false
                }
                Button(viewModel.localized(.commonSave)) {
                    submitSaveClone()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!workflowState.canSave)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private var renameSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.localized(.cloneRenameTitle))
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

    private func submitSaveClone() {
        if viewModel.saveClonedVoice(name: viewModel.clonedVoicesPageDraft.cloneName) {
            isShowingSaveSheet = false
        }
    }

    private func submitRename() {
        guard let voice = voicePendingRename else { return }
        viewModel.renameVoice(voice, to: renameVoiceName)
        voicePendingRename = nil
    }

    private var localizedMissingRequirements: [String] {
        var missing: [String] = []
        if workflowState.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(viewModel.localized(.cloneVoiceNameRequirement))
        }
        if workflowState.referenceAudioPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(viewModel.localized(.cloneReferenceAudioRequirement))
        }
        if workflowState.referenceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(viewModel.localized(.cloneReferenceTranscriptRequirement))
        }
        if workflowState.purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(viewModel.localized(.clonePurposeRequirement))
        }
        return missing
    }
}
