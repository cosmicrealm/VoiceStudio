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
                            "对话改写",
                            subtitle: "把原始小说或长文本改写成 Voice Studio 对话生成可识别的“旁白: 内容 / 角色: 台词”脚本。"
                        )
                        Spacer()
                        StudioPill(
                            title: "DeepSeek 一次改写",
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
                    StudioSectionHeader("原始文本", subtitle: "粘贴当前要改写的小说片段；长篇内容建议分段处理。")
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
                    StudioSectionHeader("改写控制", subtitle: "这些提示只影响 DeepSeek 改写，不会直接送入 TTS 模型。")
                    TextField("上文摘要，可留空", text: $viewModel.scriptRewritePageDraft.contextSummary, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    TextField("角色 / 风格提示，例如：科幻、克制、沉浸式；旁白沉稳，人物台词压抑", text: $viewModel.scriptRewritePageDraft.stylePrompt, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    deepSeekStatusPanel
                    HStack {
                        Button {
                            rewriteWithDeepSeek()
                        } label: {
                            Label(viewModel.isRewritingScriptWithDeepSeek ? "改写中" : "生成对话脚本", systemImage: "theatermasks")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canRewrite)

                        Button {
                            viewModel.scriptRewritePageDraft.sourceText = ""
                            viewModel.scriptRewritePageDraft.contextSummary = ""
                            viewModel.scriptRewritePageDraft.rewriteResult = nil
                        } label: {
                            Label("清空", systemImage: "trash")
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
                viewModel.isDeepSeekConfigured ? "DeepSeek 已配置" : "DeepSeek 未配置",
                systemImage: viewModel.isDeepSeekConfigured ? "checkmark.circle.fill" : "circle"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(viewModel.isDeepSeekConfigured ? StudioTheme.success : .secondary)
            Text(viewModel.isDeepSeekConfigured
                 ? "可联网生成对话脚本候选。"
                 : "在“设置”里配置 API key 后可使用对话改写。")
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

    private var resultColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudioPanel {
                VStack(alignment: .leading, spacing: 12) {
                    StudioSectionHeader("生成结果预览", subtitle: "确认后再应用到 Script Studio；应用时会自动切换到“对话生成”。")
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
                            Label("应用到 Script Studio", systemImage: "arrow.right.doc.on.clipboard")
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
                StudioSectionHeader("角色提示预览", subtitle: "用于后续在对话生成中绑定或创建角色音色。")
                if let result = viewModel.scriptRewritePageDraft.rewriteResult {
                    let roles = result.roles.isEmpty
                        ? SpeakerTaggedTextNormalizer.roleNames(from: result.scriptText).map {
                            DeepSeekScriptRewriteRole(name: $0, voiceHint: "")
                        }
                        : result.roles
                    if roles.isEmpty {
                        Text("暂未识别到角色。")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(roles.enumerated()), id: \.offset) { _, role in
                                HStack(alignment: .top, spacing: 8) {
                                    StudioPill(title: role.name, systemImage: role.name == "旁白" ? "text.quote" : "person.wave.2", color: .accentColor)
                                    Text(role.voiceHint.isEmpty ? "未提供声音建议" : role.voiceHint)
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
                    Text("生成后会显示 DeepSeek 返回的角色和声音建议。")
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
