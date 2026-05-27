import MacQwenVoiceCore
import SwiftUI

struct ScriptRewriteView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenScriptStudio: () -> Void
    let onOpenSettings: () -> Void

    private var trimmedSourceText: String {
        viewModel.scriptRewritePageDraft.sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canRewrite: Bool {
        viewModel.isDeepSeekConfigured
            && !viewModel.isRewritingScriptWithDeepSeek
            && !trimmedSourceText.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StudioPanel {
                    HStack(alignment: .top) {
                        StudioSectionHeader(
                            viewModel.localized(.pageScriptRewriteTitle),
                            subtitle: viewModel.localized(.pageScriptRewriteSubtitle)
                        )
                        Spacer()
                        StudioPill(
                            title: viewModel.localized(.pageScriptRewriteDeepSeekOnce),
                            systemImage: "wand.and.stars",
                            color: viewModel.isDeepSeekConfigured ? StudioTheme.success : StudioTheme.warning
                        )
                    }
                }

                HStack(alignment: .top, spacing: 16) {
                    inputColumn
                        .frame(minWidth: 560)
                    resultColumn
                        .frame(minWidth: 460)
                }
            }
            .padding(StudioTheme.pagePadding)
        }
        .onAppear {
            viewModel.refreshDeepSeekConfiguration()
        }
    }

    private var inputColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioPanel {
                VStack(alignment: .leading, spacing: 12) {
                    StudioSectionHeader(viewModel.localized(.rewriteSourceTitle), subtitle: viewModel.localized(.rewriteSourceSubtitle))
                    PlainTextEditor(text: $viewModel.scriptRewritePageDraft.sourceText)
                        .frame(minHeight: 300)
                        .background(StudioTheme.workspaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                                .stroke(StudioTheme.border, lineWidth: 1)
                        }
                }
            }

            StudioPanel {
                VStack(alignment: .leading, spacing: 12) {
                    StudioSectionHeader(viewModel.localized(.rewriteControlTitle), subtitle: viewModel.localized(.rewriteControlSubtitle))
                    TextField(viewModel.localized(.rewriteContextPlaceholder), text: $viewModel.scriptRewritePageDraft.contextSummary, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    TextField(viewModel.localized(.rewriteStylePlaceholder), text: $viewModel.scriptRewritePageDraft.stylePrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    deepSeekStatusPanel
                    HStack {
                        Button {
                            rewriteWithDeepSeek()
                        } label: {
                            Label(viewModel.isRewritingScriptWithDeepSeek ? viewModel.localized(.pageScriptRewriteGenerating) : viewModel.localized(.pageScriptRewriteGenerateScript), systemImage: "theatermasks")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canRewrite)

                        Button {
                            viewModel.scriptRewritePageDraft.sourceText = ""
                            viewModel.scriptRewritePageDraft.contextSummary = ""
                            viewModel.scriptRewritePageDraft.rewriteResult = nil
                        } label: {
                            Label(viewModel.localized(.commonClear), systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            viewModel.scriptRewritePageDraft.sourceText.isEmpty
                                && viewModel.scriptRewritePageDraft.contextSummary.isEmpty
                                && viewModel.scriptRewritePageDraft.rewriteResult == nil
                        )

                        Spacer()
                    }
                }
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
                 ? viewModel.localized(.rewriteDeepSeekConfiguredHint)
                 : viewModel.localized(.rewriteDeepSeekMissingHint))
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

    private var resultColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioPanel {
                VStack(alignment: .leading, spacing: 12) {
                    StudioSectionHeader(viewModel.localized(.rewriteResultTitle), subtitle: viewModel.localized(.rewriteResultSubtitle))
                    PlainTextEditor(
                        text: Binding(
                            get: { viewModel.scriptRewritePageDraft.rewriteResult?.scriptText ?? "" },
                            set: { value in
                                if let current = viewModel.scriptRewritePageDraft.rewriteResult {
                                    viewModel.scriptRewritePageDraft.rewriteResult = DeepSeekScriptRewriteResult(
                                        roles: current.roles,
                                        scriptText: value,
                                        warnings: current.warnings
                                    )
                                }
                            }
                        ),
                        isEditable: viewModel.scriptRewritePageDraft.rewriteResult != nil
                    )
                    .frame(minHeight: 360)
                    .background(StudioTheme.workspaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous)
                            .stroke(StudioTheme.border, lineWidth: 1)
                    }

                    HStack {
                        Button {
                            applyToScriptStudio()
                        } label: {
                            Label(viewModel.localized(.rewriteApplyToScriptStudio), systemImage: "arrow.right.doc.on.clipboard")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled((viewModel.scriptRewritePageDraft.rewriteResult?.scriptText.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty)
                        Spacer()
                    }
                }
            }

            rolePreviewPanel
        }
    }

    private var rolePreviewPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader(viewModel.localized(.rewriteRolePreviewTitle), subtitle: viewModel.localized(.rewriteRolePreviewSubtitle))
                if let result = viewModel.scriptRewritePageDraft.rewriteResult {
                    let roles = result.roles.isEmpty
                        ? SpeakerTaggedTextNormalizer.roleNames(from: result.scriptText).map {
                            DeepSeekScriptRewriteRole(name: $0, voiceHint: "")
                        }
                        : result.roles
                    if roles.isEmpty {
                        Text(viewModel.localized(.rewriteNoRoles))
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(roles.enumerated()), id: \.offset) { _, role in
                                HStack(alignment: .top, spacing: 8) {
                                    StudioPill(title: role.name, systemImage: "person.wave.2", color: .accentColor)
                                    Text(role.voiceHint.isEmpty ? viewModel.localized(.rewriteNoVoiceHint) : role.voiceHint)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    if !result.warnings.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(result.warnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(StudioTheme.warning)
                            }
                        }
                    }
                } else {
                    Text(viewModel.localized(.rewriteEmptyHint))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func rewriteWithDeepSeek() {
        viewModel.rewriteScriptWithDeepSeek(
            sourceText: viewModel.scriptRewritePageDraft.sourceText,
            contextSummary: viewModel.scriptRewritePageDraft.contextSummary,
            stylePrompt: viewModel.scriptRewritePageDraft.stylePrompt
        ) { result in
            viewModel.scriptRewritePageDraft.rewriteResult = result
        }
    }

    private func applyToScriptStudio() {
        guard let result = viewModel.scriptRewritePageDraft.rewriteResult else { return }
        viewModel.applyScriptRewriteToScriptStudio(result.scriptText)
        onOpenScriptStudio()
    }
}
