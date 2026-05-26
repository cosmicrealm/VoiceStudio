import MacQwenVoiceCore
import SwiftUI

struct ScriptStudioView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenVoiceDesign: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(2)
            if WorkspaceStartupPolicy.shouldShowManualInitBanner(
                workspaceReady: viewModel.workspaceReady,
                isInitializing: viewModel.isInitializingWorkspace
            ) {
                WorkspaceInitBanner()
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            HStack(spacing: 0) {
                editorCanvas
                    .frame(minWidth: 560, maxHeight: .infinity)
                Divider()
                GenerationResultsPanel()
                    .frame(width: 520)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            viewModel.ensureGenerationModelMatchesSelectedVoice()
        }
        .onChange(of: viewModel.selectedWorkflow) { _, workflow in
            if workflow == .multiRole {
                viewModel.scriptStudioPageDraft.isMultiRoleDesignedVoicePoolExpanded = false
            }
        }
    }

    private var topControlBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Picker("工作流", selection: workflowSelection) {
                    ForEach(ScriptStudioWorkflow.allCases) { workflow in
                        Text(workflow.title).tag(workflow)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 380)

                if viewModel.selectedWorkflow == .voiceDesign {
                    StudioPill(title: "VoiceDesign 创造生成", systemImage: "sparkles", color: .purple)
                } else if viewModel.selectedWorkflow == .multiRole {
                    StudioPill(title: "角色音色 + Base", systemImage: "person.3.sequence", color: StudioTheme.success)
                } else {
                    voicePicker
                }

                Spacer(minLength: 8)
                RuntimeStatusPill()
            }

            HStack(spacing: 12) {
                Picker("生成模型", selection: scriptStudioModelSelection) {
                    ForEach(viewModel.scriptStudioWorkflowModels) { model in
                        Text(viewModel.scriptStudioModelDisplayName(for: model)).tag(model.id)
                    }
                }
                .frame(maxWidth: 460)

                Text(modelRouteText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, StudioTheme.pagePadding)
        .padding(.vertical, 14)
        .background(StudioTheme.panelBackground)
    }

    @ViewBuilder
    private var voicePicker: some View {
        if viewModel.selectedWorkflow == .builtin {
            Picker("音色", selection: builtinVoiceSelection) {
                ForEach(viewModel.builtinVoices) { voice in
                    Text(BuiltinVoiceDisplayName.displayNameWithNativeLanguage(for: voice)).tag(Optional(voice.id))
                }
            }
            .frame(width: 260)
        } else {
            Picker("音色", selection: customVoiceSelection) {
                Text(viewModel.customVoices.isEmpty ? "暂无可复用音色" : "选择可复用音色").tag(Optional<String>.none)
                if !viewModel.clonedCustomVoices.isEmpty {
                    Section("录制/导入克隆音色") {
                        ForEach(viewModel.clonedCustomVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
                if !viewModel.designedCustomVoices.isEmpty {
                    Section("VoiceDesign 创造音色") {
                        ForEach(viewModel.designedCustomVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
            }
            .frame(width: 260)
        }
    }

    private var editorCanvas: some View {
        VStack(spacing: 0) {
            ScrollView {
                StudioPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            StudioSectionHeader("模型输入", subtitle: modelInputSubtitle)
                            Spacer()
                            Button {
                                viewModel.toggleTextDictation()
                            } label: {
                                Label(viewModel.isDictatingText ? "停止语音输入" : "语音输入", systemImage: viewModel.isDictatingText ? "stop.circle" : "mic.circle")
                            }
                            .help("调用 macOS 系统语音识别，把麦克风输入写入待生成文字。")
                        }
                        modelInputFields
                        if viewModel.selectedWorkflow == .multiRole {
                            multiRolePreparationPanel
                        }
                        if viewModel.selectedWorkflow == .multiRole {
                            synthesisTextEditor
                        } else {
                            if viewModel.currentModelInputPreview.showsInstructionEditor {
                                voiceControlDisclosure
                            }
                            if viewModel.currentModelInputPreview.showsInstructionEditor {
                                HStack(alignment: .top, spacing: 12) {
                                    generationPromptEditor(
                                        title: generationPromptTitle,
                                        placeholder: generationPromptPlaceholder
                                    )
                                    .frame(minWidth: 220, idealWidth: 280, maxWidth: 320, alignment: .topLeading)

                                    synthesisTextEditor
                                }
                            } else {
                                cloneGenerationReferenceNotice
                                synthesisTextEditor
                            }
                        }
                    }
                }
                .padding(StudioTheme.pagePadding)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Divider()
            actionBar
                .padding(.horizontal, StudioTheme.pagePadding)
                .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var modelInputFields: some View {
        let preview = viewModel.currentModelInputPreview
        return VStack(alignment: .leading, spacing: 8) {
            languageInput(preview)
            if preview.visibleFields.contains(.refAudio) || preview.visibleFields.contains(.refText) {
                referenceInput(preview)
            }
            if !preview.missingRequirements.isEmpty {
                Label("缺失：\(preview.missingRequirements.joined(separator: "、"))", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.warning)
            }
        }
    }

    private var voiceControlDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StudioSectionHeader("声音控制", subtitle: "选择或编辑控制属性后，点击应用到指令控制。")
                Spacer()
                Button {
                    viewModel.scriptStudioPageDraft.isVoiceControlExpanded.toggle()
                } label: {
                    Label(
                        viewModel.scriptStudioPageDraft.isVoiceControlExpanded ? "收起" : "展开",
                        systemImage: viewModel.scriptStudioPageDraft.isVoiceControlExpanded ? "chevron.up" : "slider.horizontal.3"
                    )
                }
                .controlSize(.small)
            }
            if viewModel.scriptStudioPageDraft.isVoiceControlExpanded {
                VoiceControlPanel()
            }
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func languageInput(_ preview: ScriptStudioModelInputPreview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("language")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 68), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(ScriptStudioLanguageChoice.toggleOptions(for: viewModel.selectedWorkflow)) { option in
                    Button {
                        viewModel.scriptStudioLanguageChoice = viewModel.scriptStudioLanguageChoice
                            .toggled(option)
                            .constrained(to: viewModel.selectedWorkflow)
                    } label: {
                        Text(option.displayTitle)
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(viewModel.scriptStudioLanguageChoice.contains(option) ? Color.accentColor : .secondary)
                }
            }
            Text(preview.languageChoice.requestHint(for: preview.text))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var synthesisTextEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.generationInputPreview.synthesisTitle)
                .font(.headline)
            Text(viewModel.selectedWorkflow == .multiRole
                 ? "用“角色名: 台词”写对话；生成时会去掉角色标签，按绑定音色逐句 Base 合成并合并为完整 WebM。"
                 : "内部会拆成 \(viewModel.segments.count) 个生成段；生成全文后会合并为完整 WebM")
                .font(.caption)
                .foregroundStyle(.secondary)
            PlainTextEditor(text: $viewModel.text) {
                viewModel.updateSegments()
            }
                .frame(minHeight: 360)
                .background(StudioTheme.workspaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                        .stroke(StudioTheme.border, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func referenceInput(_ preview: ScriptStudioModelInputPreview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("已绑定参考音频")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        StudioPill(title: viewModel.selectedVoiceChainLabel, systemImage: referenceSourceIcon, color: referenceSourceColor)
                    }
                    Text(referenceAudioName(preview.refAudioPath))
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(preview.refAudioPath == nil ? StudioTheme.warning : .primary)
                        .textSelection(.enabled)
                    Text(viewModel.audioDurationLabel(path: preview.refAudioPath))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AudioPlayButton(
                    "试听",
                    item: preview.refAudioPath.map { AudioPlaybackItem.file(path: $0, context: "script-reference") }
                )
                .controlSize(.small)
                .disabled(preview.refAudioPath == nil)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("参考逐字稿")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(preview.refText ?? "缺失")
                    .font(.caption)
                    .lineLimit(4)
                    .foregroundStyle(preview.refText == nil ? StudioTheme.warning : .primary)
                    .textSelection(.enabled)
                Text("Base 复用固定使用保存音色时绑定的 reference transcript，避免参考音频和逐字稿错配。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var referenceSourceIcon: String {
        viewModel.selectedVoiceKind == .voiceDesign ? "sparkles" : "waveform.badge.mic"
    }

    private var referenceSourceColor: Color {
        viewModel.selectedVoiceKind == .voiceDesign ? .purple : Color.accentColor
    }

    private func referenceAudioName(_ path: String?) -> String {
        guard let path, !path.isEmpty else { return "缺失" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private var multiRolePreparationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StudioSectionHeader("角色音色绑定", subtitle: "每个角色必须绑定一个已保存的克隆音色或创造音色；Base 逐句复用 ref_audio/ref_text。")
                Spacer()
                Text("角色音色 + Base")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            multiRoleDesignedVoicePool

            if viewModel.multiRoleVoicePreparationItems.isEmpty {
                HStack(spacing: 10) {
                    Label("在合成文本里写“角色名: 台词”。系统会解析角色列表；每个角色都需要在这里绑定已保存音色。", systemImage: "person.3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StudioTheme.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
            } else {
                ForEach(viewModel.multiRoleVoicePreparationItems) { item in
                    multiRolePreparationRow(item)
                }
            }
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var multiRoleDesignedVoicePool: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    viewModel.scriptStudioPageDraft.isMultiRoleDesignedVoicePoolExpanded.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.scriptStudioPageDraft.isMultiRoleDesignedVoicePoolExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .frame(width: 12)
                        Text("创造音色池")
                            .font(.caption.weight(.semibold))
                        StudioPill(
                            title: VoiceSelectionSummary.countLabel(
                                selectedCount: viewModel.multiRoleSelectedDesignedVoiceIDs.count,
                                totalCount: viewModel.designedCustomVoices.count
                            ),
                            systemImage: "checklist",
                            color: viewModel.multiRoleSelectedDesignedVoiceIDs.isEmpty ? .secondary : .purple
                        )
                        Text(VoiceSelectionSummary.namesSummary(viewModel.multiRoleSelectedDesignedVoices.map(\.name)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
                if !viewModel.multiRoleSelectedDesignedVoiceIDs.isEmpty {
                    Button("清空") {
                        viewModel.clearDesignedVoicesForMultiRole()
                    }
                    .controlSize(.small)
                }
            }

            if viewModel.scriptStudioPageDraft.isMultiRoleDesignedVoicePoolExpanded {
                if viewModel.designedCustomVoices.isEmpty {
                    Text("暂无创造音色。先在左侧“创造音色”保存角色声音，再回到这里选择使用。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.designedCustomVoices) { voice in
                                designedVoicePoolItem(voice)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxHeight: 220)
                }
            }
        }
        .padding(10)
        .background(StudioTheme.workspaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func designedVoicePoolItem(_ voice: VoiceProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { viewModel.isMultiRoleDesignedVoiceSelected(voice) },
                set: { viewModel.setMultiRoleDesignedVoice(voice, selected: $0) }
            )) {
                Text(voice.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .toggleStyle(.checkbox)

            Text((voice.referenceText ?? "缺少 ref_text").trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.caption2)
                .foregroundStyle(voice.referenceText == nil ? StudioTheme.warning : .secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                StudioPill(title: "创造音色", systemImage: "sparkles", color: .purple)
                Spacer()
                AudioPlayButton(
                    "试听",
                    item: voice.referenceAudioPath.map { AudioPlaybackItem.file(path: $0, context: "multi-role-designed-\(voice.id)") }
                )
                .labelStyle(.iconOnly)
                .controlSize(.small)
                .disabled((voice.referenceAudioPath ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(8)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func multiRolePreparationRow(_ item: MultiRoleVoicePreparationItem) -> some View {
        return HStack(alignment: .top, spacing: 10) {
            StudioPill(title: item.status.title, systemImage: multiRoleStatusIcon(item.status), color: multiRoleStatusColor(item.status))
                .frame(width: 86, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.roleName)
                    .font(.caption.weight(.semibold))
                HStack(spacing: 6) {
                    StudioPill(title: item.sourceKind.title, systemImage: multiRoleSourceIcon(item.sourceKind), color: multiRoleSourceColor(item.sourceKind))
                    Text(item.boundVoiceName ?? "未绑定音色")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(item.instruction)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                Text("ref_text：\(item.boundReferenceText ?? item.referenceText)")
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                if !item.missingRequirements.isEmpty {
                    Text("缺少：\(item.missingRequirements.joined(separator: "、"))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(StudioTheme.warning)
                }
            }
            Spacer()
            Picker("绑定音色", selection: multiRoleVoiceSelection(for: item.roleName)) {
                Text("未绑定").tag(Optional<String>.none)
                if !viewModel.multiRoleSelectedDesignedVoices.isEmpty {
                    Section("已选创造音色") {
                        ForEach(viewModel.multiRoleSelectedDesignedVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
                if !viewModel.clonedCustomVoices.isEmpty {
                    Section("克隆音色") {
                        ForEach(viewModel.clonedCustomVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
                if !viewModel.multiRoleUnselectedDesignedVoices.isEmpty {
                    Section("其他创造音色") {
                        ForEach(viewModel.multiRoleUnselectedDesignedVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
            }
            .labelsHidden()
            .frame(width: 190)
            AudioPlayButton(
                "试听",
                item: item.referenceAudioPath.map { AudioPlaybackItem.file(path: $0, context: "multi-role-\(item.id)") }
            )
            .controlSize(.small)
            .disabled(item.referenceAudioPath == nil)
        }
        .padding(8)
        .background(StudioTheme.workspaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private func multiRoleStatusIcon(_ status: MultiRoleVoicePreparationStatus) -> String {
        switch status {
        case .missing:
            "exclamationmark.circle"
        case .generating:
            "hourglass"
        case .ready:
            "checkmark.circle.fill"
        case .failed:
            "xmark.circle.fill"
        }
    }

    private func multiRoleStatusColor(_ status: MultiRoleVoicePreparationStatus) -> Color {
        switch status {
        case .missing:
            StudioTheme.warning
        case .generating:
            Color.accentColor
        case .ready:
            StudioTheme.success
        case .failed:
            StudioTheme.danger
        }
    }

    private func multiRoleSourceIcon(_ source: MultiRoleVoiceSourceKind) -> String {
        switch source {
        case .unbound:
            "questionmark.circle"
        case .clonedVoice:
            "waveform.badge.mic"
        case .voiceDesign:
            "sparkles"
        case .generatedFromPrompt:
            "sparkles"
        }
    }

    private func multiRoleSourceColor(_ source: MultiRoleVoiceSourceKind) -> Color {
        switch source {
        case .unbound:
            StudioTheme.warning
        case .clonedVoice:
            Color.accentColor
        case .voiceDesign:
            .purple
        case .generatedFromPrompt:
            .purple
        }
    }

    private func modelInputValue(_ title: String, value: String, warning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(warning ? StudioTheme.warning : .primary)
                .textSelection(.enabled)
        }
        .frame(minWidth: 110, maxWidth: 220, alignment: .leading)
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var generationPromptTitle: String {
        return "指令控制"
    }

    private var generationPromptPlaceholder: String {
        return "未设置控制指令；将使用所选音色的默认风格。"
    }

    private func generationPromptEditor(title: String, placeholder: String) -> some View {
        let preview = viewModel.currentModelInputPreview
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(preview.disabledInstructReason ?? "最终送入模型的控制指令")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Spacer()
                Button {
                    viewModel.randomizeGenerationControlInstruction()
                } label: {
                    Label("随机生成", systemImage: "shuffle")
                }
                .controlSize(.small)
                .disabled(!preview.showsInstructionEditor)
                Button {
                    viewModel.resetGenerationControlInstructionToCompiled()
                } label: {
                    Label("恢复默认指令", systemImage: "arrow.counterclockwise")
                }
                .controlSize(.small)
                .disabled(!preview.showsInstructionEditor)
            }
            PlainTextEditor(
                text: generationControlInstructionBinding,
                isEditable: preview.showsInstructionEditor
            )
            .frame(minHeight: 360)
            .background(StudioTheme.workspaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                    .stroke(StudioTheme.border, lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                if viewModel.editableGenerationControlInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .opacity(preview.showsInstructionEditor ? 1 : 0.55)
        }
    }

    private var cloneGenerationReferenceNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "waveform.badge.mic")
                .foregroundStyle(Color.accentColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text("克隆生成不使用指令控制")
                    .font(.headline)
                Text("音色来自 RefAudio 和 RefText；生成时会复用所选音色绑定的参考音频和参考逐字稿，不再额外传入控制指令。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var generationControlInstructionBinding: Binding<String> {
        Binding(
            get: { viewModel.editableGenerationControlInstruction },
            set: { viewModel.updateGenerationControlInstruction($0) }
        )
    }

    private var actionBar: some View {
        StudioPanel {
            HStack(spacing: 10) {
                StudioToolbarButton(
                    title: viewModel.isGeneratingAllSegments ? "取消队列" : "生成全文",
                    systemImage: viewModel.isGeneratingAllSegments ? "stop.circle" : "waveform",
                    prominent: !viewModel.isGeneratingAllSegments
                ) {
                    if viewModel.isGeneratingAllSegments {
                        viewModel.cancelAllGeneration()
                    } else {
                        viewModel.generateAllSegments()
                    }
                }
                .disabled(!viewModel.isGeneratingAllSegments && !viewModel.currentModelInputPreview.missingRequirements.isEmpty)
                StudioToolbarButton(
                    title: viewModel.playAllControlState.title,
                    systemImage: viewModel.playAllControlState.systemImage
                ) {
                    viewModel.togglePlayAllGenerated()
                }
                StudioToolbarButton(
                    title: viewModel.isMergingFullGeneratedAudio ? "合成中" : "导出全文",
                    systemImage: "square.and.arrow.up"
                ) {
                    viewModel.exportAllGenerated()
                }
                .disabled(!viewModel.canExportFullGeneratedAudio)
                if viewModel.hasMergedFullGeneratedAudio {
                    StudioPill(title: "已合并完整 WebM", systemImage: "waveform.path", color: StudioTheme.success)
                }
                if viewModel.hasPlayableGeneratedAudio {
                    Text(viewModel.generatedPlaybackDurationLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
    }

    private var modelInputSubtitle: String {
        let preview = viewModel.currentModelInputPreview
        if viewModel.hasRoleRoutedScript {
            return viewModel.selectedWorkflow == .multiRole
                ? "对话生成：只使用已绑定角色音色，Base 逐句合成后合并为完整 WebM。"
                : "检测到多角色脚本：请切换到“对话生成”以避免角色声线漂移。"
        }
        switch viewModel.selectedWorkflow {
        case .builtin:
            return "CustomVoice：确认 language，编辑指令控制，音色由上方选择。"
        case .custom:
            return preview.disabledInstructReason ?? "Base Clone：确认 language，并使用可复用音色绑定的参考组。"
        case .voiceDesign:
            return "VoiceDesign：确认 language，编辑声音设计指令。"
        case .multiRole:
            return "对话生成：在合成文本里写角色台词，并为每个角色绑定已保存音色。"
        }
    }

    private var modelRouteText: String {
        if viewModel.selectedWorkflow == .multiRole {
            return "对话生成：角色音色 + Base 逐句复用并合并"
        }
        if viewModel.hasRoleRoutedScript {
            return "检测到角色脚本：请切换到对话生成"
        }
        switch viewModel.selectedWorkflow {
        case .builtin:
            return "CustomVoice：精品 speaker 与风格控制"
        case .custom:
            return "Base Clone：复用克隆音色或创造音色"
        case .voiceDesign:
            return "VoiceDesign：用自然语言描述直接创造声音"
        case .multiRole:
            return "对话生成：角色音色 + Base"
        }
    }

    private var workflowSelection: Binding<ScriptStudioWorkflow> {
        Binding(
            get: { viewModel.selectedWorkflow },
            set: { viewModel.selectScriptStudioWorkflow($0) }
        )
    }

    private func multiRoleVoiceSelection(for roleName: String) -> Binding<String?> {
        Binding(
            get: { viewModel.multiRoleVoiceBindings[roleName] },
            set: { viewModel.selectMultiRoleVoice(speaker: roleName, voiceID: $0) }
        )
    }

    private var scriptStudioModelSelection: Binding<String> {
        Binding(
            get: { viewModel.selectedModelID },
            set: { viewModel.selectScriptStudioModel(id: $0) }
        )
    }

    private var builtinVoiceSelection: Binding<String?> {
        Binding(
            get: {
                viewModel.builtinVoices.contains { $0.id == viewModel.selectedVoiceID } ? viewModel.selectedVoiceID : nil
            },
            set: { newValue in
                if let newValue {
                    viewModel.selectVoice(id: newValue)
                }
            }
        )
    }

    private var customVoiceSelection: Binding<String?> {
        Binding(
            get: {
                viewModel.customVoices.contains { $0.id == viewModel.selectedVoiceID } ? viewModel.selectedVoiceID : nil
            },
            set: { newValue in
                if let newValue {
                    viewModel.selectVoice(id: newValue)
                }
            }
        )
    }
}

struct VoiceControlPanel: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    private var definitions: [VoiceControlAttributeDefinition] {
        VoiceControlAttributeCatalog.definitions(for: viewModel.selectedWorkflow)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                StudioSectionHeader("声音控制")
                Spacer()
                StudioPill(title: routeTitle, systemImage: routeIcon, color: routeColor)
                Button {
                    viewModel.applyCompiledVoiceControlPromptToScriptStudio()
                } label: {
                    Label("应用到指令控制", systemImage: "arrow.down.doc")
                }
                .controlSize(.small)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VoiceControlPreset.recommendedForScriptStudio(workflow: viewModel.selectedWorkflow)) { preset in
                        Button(preset.title) {
                            viewModel.applyVoiceControlPreset(preset)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.bottom, 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(definitions) { definition in
                        attributeField(definition)
                    }
                }
                .padding(.trailing, 4)
            }
            .frame(maxHeight: 360)

            TextField(supplementalPromptTitle, text: supplementalPromptBinding, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private var supplementalPromptTitle: String {
        viewModel.selectedWorkflow == .voiceDesign ? "补充声音身份描述" : "补充演绎指令"
    }

    private var supplementalPromptBinding: Binding<String> {
        Binding(
            get: {
                viewModel.selectedWorkflow == .voiceDesign
                    ? viewModel.voiceIdentityDescription
                    : viewModel.instruct
            },
            set: { value in
                if viewModel.selectedWorkflow == .voiceDesign {
                    viewModel.voiceIdentityDescription = value
                } else {
                    viewModel.instruct = value
                }
            }
        )
    }

    private var routeTitle: String {
        switch viewModel.selectedWorkflow {
        case .builtin: "CustomVoice"
        case .custom: "Base Clone"
        case .voiceDesign: "VoiceDesign"
        case .multiRole: "对话生成"
        }
    }

    private var routeIcon: String {
        switch viewModel.selectedWorkflow {
        case .builtin: "person.wave.2"
        case .custom: "waveform.badge.mic"
        case .voiceDesign: "sparkles"
        case .multiRole: "person.3.sequence"
        }
    }

    private var routeColor: Color {
        switch viewModel.selectedWorkflow {
        case .builtin: Color.accentColor
        case .custom: StudioTheme.success
        case .voiceDesign: .purple
        case .multiRole: StudioTheme.success
        }
    }

    private func attributeField(_ definition: VoiceControlAttributeDefinition) -> some View {
        let text = binding(for: definition.id)
        let candidates = candidates(for: definition)
        return VStack(alignment: .leading, spacing: 4) {
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
        VoiceControlAttributeCatalog.candidates(for: definition.id, workflow: viewModel.selectedWorkflow)
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
}
