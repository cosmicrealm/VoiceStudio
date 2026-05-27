import MacQwenVoiceCore
import SwiftUI

struct ScriptStudioView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenVoiceDesign: () -> Void

    private var interfaceLanguage: AppLanguage { viewModel.effectiveAppLanguage }
    private func t(_ key: AppLocalizationKey) -> String { viewModel.localized(key) }
    private func t(_ key: AppLocalizationKey, _ argument: String) -> String { viewModel.localized(key, argument) }

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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                workflowTabs
                    .layoutPriority(1)

                Spacer(minLength: 12)

                RuntimeStatusPill()
                    .layoutPriority(2)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    workflowRouteControl
                    generationModelPicker
                    Text(modelRouteText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        workflowRouteControl
                        generationModelPicker
                        Spacer(minLength: 8)
                    }
                    Text(modelRouteText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, StudioTheme.pagePadding)
        .padding(.vertical, 14)
        .background(StudioTheme.panelBackground)
    }

    private var workflowTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ScriptStudioWorkflow.allCases) { workflow in
                    workflowTabButton(workflow)
                }
            }
            .padding(2)
        }
        .accessibilityLabel(t(.scriptWorkflow))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func workflowTabButton(_ workflow: ScriptStudioWorkflow) -> some View {
        let isSelected = viewModel.selectedWorkflow == workflow
        return Button {
            viewModel.selectScriptStudioWorkflow(workflow)
        } label: {
            Text(workflow.title(language: interfaceLanguage))
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .frame(minWidth: workflowTabMinimumWidth(for: workflow), minHeight: 34)
                .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .background(isSelected ? Color.accentColor : StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func workflowTabMinimumWidth(for workflow: ScriptStudioWorkflow) -> CGFloat {
        switch interfaceLanguage {
        case .simplifiedChinese, .traditionalChinese, .japanese, .korean:
            return 116
        case .english:
            return workflow == .multiRole ? 180 : 154
        case .russian:
            return workflow == .multiRole ? 230 : 190
        case .spanish, .portuguese, .french, .german, .italian:
            return workflow == .multiRole ? 220 : 176
        case .system:
            return 154
        }
    }

    @ViewBuilder
    private var workflowRouteControl: some View {
        if viewModel.selectedWorkflow == .voiceDesign {
            StudioPill(title: viewModel.selectedWorkflow.title(language: interfaceLanguage), systemImage: "sparkles", color: .purple)
                .frame(minWidth: 220, maxWidth: 320, alignment: .leading)
        } else if viewModel.selectedWorkflow == .multiRole {
            StudioPill(title: t(.scriptRoleVoiceRoute), systemImage: "person.3.sequence", color: StudioTheme.success)
                .frame(minWidth: 220, maxWidth: 320, alignment: .leading)
        } else {
            voicePicker
        }
    }

    private var generationModelPicker: some View {
        HStack(spacing: 8) {
            Text(t(.scriptGenerationModel))
                .font(.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(minWidth: 110, idealWidth: 150, maxWidth: 190, alignment: .trailing)

            Picker("", selection: scriptStudioModelSelection) {
                ForEach(viewModel.scriptStudioWorkflowModels) { model in
                    Text(viewModel.scriptStudioModelDisplayName(for: model)).tag(model.id)
                }
            }
            .labelsHidden()
            .frame(width: 360)
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    @ViewBuilder
    private var voicePicker: some View {
        if viewModel.selectedWorkflow == .builtin {
            Picker(t(.scriptVoice), selection: builtinVoiceSelection) {
                ForEach(viewModel.builtinVoices) { voice in
                    Text(BuiltinVoiceDisplayName.displayNameWithNativeLanguage(for: voice)).tag(Optional(voice.id))
                }
            }
            .frame(width: 300)
        } else {
            Picker(t(.scriptVoice), selection: customVoiceSelection) {
                Text(viewModel.customVoices.isEmpty ? t(.scriptNoReusableVoice) : t(.scriptSelectReusableVoice)).tag(Optional<String>.none)
                if !viewModel.clonedCustomVoices.isEmpty {
                    Section(t(.scriptRecordedClonedVoices)) {
                        ForEach(viewModel.clonedCustomVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
                if !viewModel.designedCustomVoices.isEmpty {
                    Section(t(.scriptDesignedVoices)) {
                        ForEach(viewModel.designedCustomVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
            }
            .frame(width: 300)
        }
    }

    private var editorCanvas: some View {
        VStack(spacing: 0) {
            ScrollView {
                StudioPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            StudioSectionHeader(t(.scriptModelInputTitle), subtitle: modelInputSubtitle)
                            Spacer()
                            Button {
                                viewModel.toggleTextDictation()
                            } label: {
                                Label(
                                    viewModel.isDictatingText ? t(.scriptStopVoiceInput) : t(.scriptVoiceInput),
                                    systemImage: viewModel.isDictatingText ? "stop.circle" : "mic.circle"
                                )
                            }
                            .help(t(.scriptVoiceInputHelp))
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
                Label(t(.scriptMissingFormat, preview.missingRequirements.joined(separator: ", ")), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(StudioTheme.warning)
            }
        }
    }

    private var voiceControlDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StudioSectionHeader(t(.scriptVoiceControlTitle), subtitle: t(.scriptVoiceControlSubtitle))
                Spacer()
                Button {
                    viewModel.scriptStudioPageDraft.isVoiceControlExpanded.toggle()
                } label: {
                    Label(
                        viewModel.scriptStudioPageDraft.isVoiceControlExpanded ? t(.scriptCollapse) : t(.scriptExpand),
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
                        Text(option.displayTitle(language: interfaceLanguage))
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(viewModel.scriptStudioLanguageChoice.contains(option) ? Color.accentColor : .secondary)
                }
            }
            Text(preview.languageChoice.requestHint(for: preview.text, language: interfaceLanguage))
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
            Text(t(.scriptSynthesisText))
                .font(.headline)
            Text(viewModel.selectedWorkflow == .multiRole
                 ? t(.scriptMultiRoleSynthesisHint)
                 : t(.scriptDefaultSynthesisHintFormat, "\(viewModel.segments.count)"))
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
                        Text(t(.scriptBoundReferenceAudio))
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
                    t(.commonPreview),
                    item: preview.refAudioPath.map { AudioPlaybackItem.file(path: $0, context: "script-reference") }
                )
                .controlSize(.small)
                .disabled(preview.refAudioPath == nil)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(t(.scriptReferenceTranscript))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(preview.refText ?? t(.commonMissing))
                    .font(.caption)
                    .lineLimit(4)
                    .foregroundStyle(preview.refText == nil ? StudioTheme.warning : .primary)
                    .textSelection(.enabled)
                Text(t(.scriptReferenceTranscriptNote))
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
        guard let path, !path.isEmpty else { return t(.commonMissing) }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private var multiRolePreparationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StudioSectionHeader(t(.scriptRoleVoiceBindingTitle), subtitle: t(.scriptRoleVoiceBindingSubtitle))
                Spacer()
                Text(t(.scriptRoleVoiceRoute))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            multiRoleDesignedVoicePool

            if viewModel.multiRoleVoicePreparationItems.isEmpty {
                HStack(spacing: 10) {
                    Label(t(.scriptRoleVoiceEmptyHint), systemImage: "person.3")
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
                        Text(t(.scriptDesignedVoicePool))
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
                    Button(t(.commonClearSelection)) {
                        viewModel.clearDesignedVoicesForMultiRole()
                    }
                    .controlSize(.small)
                }
            }

            if viewModel.scriptStudioPageDraft.isMultiRoleDesignedVoicePoolExpanded {
                if viewModel.designedCustomVoices.isEmpty {
                    Text(t(.scriptNoDesignedVoiceHint))
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

            Text((voice.referenceText ?? t(.scriptMissingRefText)).trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.caption2)
                .foregroundStyle(voice.referenceText == nil ? StudioTheme.warning : .secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                StudioPill(title: t(.workspaceVoiceDesign), systemImage: "sparkles", color: .purple)
                Spacer()
                AudioPlayButton(
                    t(.commonPreview),
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
            StudioPill(title: multiRoleStatusTitle(item.status), systemImage: multiRoleStatusIcon(item.status), color: multiRoleStatusColor(item.status))
                .frame(width: 86, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.roleName)
                    .font(.caption.weight(.semibold))
                HStack(spacing: 6) {
                    StudioPill(title: multiRoleSourceTitle(item.sourceKind), systemImage: multiRoleSourceIcon(item.sourceKind), color: multiRoleSourceColor(item.sourceKind))
                    Text(item.boundVoiceName ?? t(.scriptUnboundVoice))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(item.instruction)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                Text(t(.scriptRefTextFormat, item.boundReferenceText ?? item.referenceText))
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                if !item.missingRequirements.isEmpty {
                    Text(t(.scriptMissingFormat, item.missingRequirements.joined(separator: ", ")))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(StudioTheme.warning)
                }
            }
            Spacer()
            Picker(t(.scriptBindVoice), selection: multiRoleVoiceSelection(for: item.roleName)) {
                Text(t(.scriptUnbound)).tag(Optional<String>.none)
                if !viewModel.multiRoleSelectedDesignedVoices.isEmpty {
                    Section(t(.scriptSelectedDesignedVoices)) {
                        ForEach(viewModel.multiRoleSelectedDesignedVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
                if !viewModel.clonedCustomVoices.isEmpty {
                    Section(t(.workspaceClonedVoices)) {
                        ForEach(viewModel.clonedCustomVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
                if !viewModel.multiRoleUnselectedDesignedVoices.isEmpty {
                    Section(t(.scriptOtherDesignedVoices)) {
                        ForEach(viewModel.multiRoleUnselectedDesignedVoices) { voice in
                            Text(voice.name).tag(Optional(voice.id))
                        }
                    }
                }
            }
            .labelsHidden()
            .frame(width: 190)
            AudioPlayButton(
                t(.commonPreview),
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

    private func multiRoleStatusTitle(_ status: MultiRoleVoicePreparationStatus) -> String {
        switch status {
        case .missing:
            return t(.scriptUnbound)
        case .generating:
            return t(.generationRunningTitle)
        case .ready:
            return t(.modelReady)
        case .failed:
            return t(.runtimeInstallFailed)
        }
    }

    private func multiRoleSourceTitle(_ source: MultiRoleVoiceSourceKind) -> String {
        switch source {
        case .unbound:
            return t(.scriptUnbound)
        case .clonedVoice:
            return t(.workspaceClonedVoices)
        case .voiceDesign, .generatedFromPrompt:
            return t(.workspaceVoiceDesign)
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
        return t(.scriptGenerationControlTitle)
    }

    private var generationPromptPlaceholder: String {
        return t(.scriptGenerationControlPlaceholder)
    }

    private func generationPromptEditor(title: String, placeholder: String) -> some View {
        let preview = viewModel.currentModelInputPreview
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(preview.disabledInstructReason ?? t(.scriptFinalControlInstruction))
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Spacer()
                Button {
                    viewModel.randomizeGenerationControlInstruction()
                } label: {
                    Label(t(.scriptRandomGenerate), systemImage: "shuffle")
                }
                .controlSize(.small)
                .disabled(!preview.showsInstructionEditor)
                Button {
                    viewModel.resetGenerationControlInstructionToCompiled()
                } label: {
                    Label(t(.scriptRestoreDefaultInstruction), systemImage: "arrow.counterclockwise")
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
                Text(t(.scriptCloneNoInstructionTitle))
                    .font(.headline)
                Text(t(.scriptCloneNoInstructionSubtitle))
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
                    title: viewModel.isGeneratingAllSegments ? t(.scriptCancelQueue) : t(.scriptGenerateFullText),
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
                    title: viewModel.playAllControlState.title(language: interfaceLanguage),
                    systemImage: viewModel.playAllControlState.systemImage
                ) {
                    viewModel.togglePlayAllGenerated()
                }
                StudioToolbarButton(
                    title: viewModel.isMergingFullGeneratedAudio ? t(.scriptMerging) : t(.scriptExportFullText),
                    systemImage: "square.and.arrow.up"
                ) {
                    viewModel.exportAllGenerated()
                }
                .disabled(!viewModel.canExportFullGeneratedAudio)
                if viewModel.hasMergedFullGeneratedAudio {
                    StudioPill(title: t(.scriptMergedFullWebM), systemImage: "waveform.path", color: StudioTheme.success)
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
        if viewModel.hasRoleRoutedScript {
            return viewModel.selectedWorkflow == .multiRole
                ? t(.scriptModelInputSubtitleMultiRole)
                : t(.scriptModelInputSubtitleRoleWarning)
        }
        switch viewModel.selectedWorkflow {
        case .builtin:
            return t(.scriptModelInputSubtitleBuiltin)
        case .custom:
            return t(.scriptModelInputSubtitleCustom)
        case .voiceDesign:
            return t(.scriptModelInputSubtitleVoiceDesign)
        case .multiRole:
            return t(.scriptModelInputSubtitleMultiRole)
        }
    }

    private var modelRouteText: String {
        if viewModel.selectedWorkflow == .multiRole {
            return t(.scriptRouteMultiRole)
        }
        if viewModel.hasRoleRoutedScript {
            return t(.scriptRouteRoleWarning)
        }
        switch viewModel.selectedWorkflow {
        case .builtin:
            return t(.scriptRouteBuiltin)
        case .custom:
            return t(.scriptRouteCustom)
        case .voiceDesign:
            return t(.scriptRouteVoiceDesign)
        case .multiRole:
            return t(.scriptRoleVoiceRoute)
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

    private var interfaceLanguage: AppLanguage { viewModel.effectiveAppLanguage }
    private func t(_ key: AppLocalizationKey) -> String { viewModel.localized(key) }
    private func t(_ key: AppLocalizationKey, _ argument: String) -> String { viewModel.localized(key, argument) }

    private var definitions: [VoiceControlAttributeDefinition] {
        VoiceControlAttributeCatalog.definitions(for: viewModel.selectedWorkflow, language: interfaceLanguage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                StudioSectionHeader(t(.scriptVoiceControlTitle))
                Spacer()
                StudioPill(title: routeTitle, systemImage: routeIcon, color: routeColor)
                Button {
                    viewModel.applyCompiledVoiceControlPromptToScriptStudio()
                } label: {
                    Label(t(.scriptApplyToInstruction), systemImage: "arrow.down.doc")
                }
                .controlSize(.small)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VoiceControlPreset.recommendedForScriptStudio(workflow: viewModel.selectedWorkflow)) { preset in
                        Button(preset.title(language: interfaceLanguage)) {
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
        viewModel.selectedWorkflow == .voiceDesign ? t(.scriptSupplementalVoiceIdentity) : t(.scriptSupplementalPerformance)
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
        case .multiRole: viewModel.selectedWorkflow.title(language: interfaceLanguage)
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
                Picker(t(.scriptChooseAttributeFormat, definition.title), selection: candidateSelection(text: text, candidates: candidates)) {
                    Text(t(.scriptNotSpecified)).tag("")
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
        VoiceControlAttributeCatalog.candidates(for: definition.id, workflow: viewModel.selectedWorkflow, language: interfaceLanguage)
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
