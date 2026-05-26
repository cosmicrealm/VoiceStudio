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
            "删除克隆音色？",
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

    private var pageHeader: some View {
        StudioPanel {
            HStack {
                StudioSectionHeader("本地音色克隆", subtitle: "录入一段授权参考音频和逐字稿，保存后在 Voice Studio 的克隆生成/对话生成中复用。")
                Spacer()
                StudioPill(title: "\(viewModel.voices.filter { $0.kind == .clonedVoice }.count) 个克隆音色", systemImage: "waveform.badge.mic", color: Color.accentColor)
            }
        }
    }

    private var transcriptPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader("1. 参考逐字稿", subtitle: "直接编辑这段文字；录音内容尽量逐字匹配。")
                TextField("请让录音内容逐字匹配这里的文本", text: $viewModel.cloneReferenceText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                HStack {
                    Button {
                        viewModel.fillCloneTranscriptFromCurrentScript()
                    } label: {
                        Label("用当前旁白填入", systemImage: "text.quote")
                    }
                    Button {
                        viewModel.clearCloneTranscript()
                    } label: {
                        Label("清空", systemImage: "xmark.circle")
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
                    ForEach(VoiceStudioDefaults.cloneReferenceTranscriptExamples, id: \.language) { group in
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
                    StudioSectionHeader("参考逐字稿示例", subtitle: "可选。点击候选句会替换第 1 步文本。")
                    Spacer()
                    StudioPill(
                        title: "\(VoiceStudioDefaults.cloneReferenceTranscriptExamples.reduce(0) { $0 + $1.examples.count }) 条",
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
                StudioSectionHeader("2. 参考音频", subtitle: "导入或录制后先试听，确认逐字稿匹配后保存为克隆音色。")
                HStack {
                    Button {
                        viewModel.chooseReferenceAudio()
                    } label: {
                        Label("导入音频", systemImage: "folder")
                    }
                    Button {
                        viewModel.isRecordingReference ? viewModel.stopReferenceRecording() : viewModel.startReferenceRecording()
                    } label: {
                        Label(viewModel.isRecordingReference ? "停止录音" : "录制参考音频", systemImage: viewModel.isRecordingReference ? "stop.circle" : "mic.circle")
                    }
                    AudioPlayButton(
                        "播放参考音频",
                        pauseTitle: "暂停参考音频",
                        item: viewModel.cloneReferenceAudioPath.isEmpty
                            ? nil
                            : AudioPlaybackItem.file(path: viewModel.cloneReferenceAudioPath, context: "clone-reference")
                    )
                    Button(role: .destructive) {
                        viewModel.clearCloneReferenceAudio(deleteFile: true)
                    } label: {
                        Label("删除当前参考音频", systemImage: "trash")
                    }
                    .disabled(viewModel.cloneReferenceAudioPath.isEmpty)
                }
                HStack {
                    Button {
                        isShowingSaveSheet = true
                    } label: {
                        Label("保存为克隆音色", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasReferenceInput)
                    StudioPill(
                        title: hasReferenceInput ? "可保存" : "还缺：\(referenceInputMissingText)",
                        systemImage: hasReferenceInput ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                        color: hasReferenceInput ? StudioTheme.success : StudioTheme.warning
                    )
                    Spacer()
                }
                TextField("参考音频路径", text: $viewModel.cloneReferenceAudioPath)
                    .textFieldStyle(.roundedBorder)
                    .textSelection(.enabled)
                HStack {
                    StudioPill(
                        title: workflowState.referenceAudioPath.isEmpty ? "未录入参考音频" : "参考音频已录入",
                        systemImage: workflowState.referenceAudioPath.isEmpty ? "exclamationmark.triangle" : "checkmark.circle.fill",
                        color: workflowState.referenceAudioPath.isEmpty ? StudioTheme.warning : StudioTheme.success
                    )
                    Text("时长：\(workflowState.durationText)")
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
                StudioSectionHeader("已保存克隆音色", subtitle: "管理、重命名、删除或发送到 Voice Studio 使用。")
                let clonedVoices = viewModel.voices.filter { $0.kind == .clonedVoice }
                if clonedVoices.isEmpty {
                    Text("还没有克隆音色。完成左侧参考逐字稿和参考音频后会显示在这里。")
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
                    Text(voice.referenceAudioPath ?? "未记录参考音频")
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
                        Label("用于生成", systemImage: "arrow.right.circle")
                    }
                    Button {
                        viewModel.selectVoice(voice)
                        viewModel.prepareCloneTestScript()
                        onOpenScriptStudio()
                    } label: {
                        Label("生成测试句", systemImage: "text.badge.checkmark")
                    }
                    Spacer()
                }
                HStack {
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
            missing.append("参考音频")
        }
        if viewModel.cloneReferenceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("参考逐字稿")
        }
        return missing.joined(separator: "、")
    }

    private func transcriptExampleButton(_ example: String) -> some View {
        Button {
            viewModel.cloneReferenceText = example
            viewModel.statusMessage = "已填入参考逐字稿示例"
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
            Text("保存为克隆音色")
                .font(.headline)
            TextField("克隆音色名称", text: $viewModel.clonedVoicesPageDraft.cloneName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    submitSaveClone()
                }
            TextField("授权用途说明", text: $viewModel.clonePurpose, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            StudioPill(
                title: workflowState.canSave ? "可保存为克隆音色" : "还缺：\(workflowState.missingRequirements.joined(separator: "、"))",
                systemImage: workflowState.canSave ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                color: workflowState.canSave ? StudioTheme.success : StudioTheme.warning
            )
            HStack {
                Spacer()
                Button("取消") {
                    isShowingSaveSheet = false
                }
                Button("保存") {
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
            Text("重命名克隆音色")
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
}
