import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StudioPanel {
                    HStack(alignment: .top) {
                        StudioSectionHeader("设置", subtitle: "集中管理联网大模型、工作流增强和本地配置。")
                        Spacer()
                        StudioPill(
                            title: viewModel.isDeepSeekConfigured ? "DeepSeek 已配置" : "DeepSeek 未配置",
                            systemImage: viewModel.isDeepSeekConfigured ? "checkmark.circle.fill" : "circle",
                            color: viewModel.isDeepSeekConfigured ? StudioTheme.success : .secondary
                        )
                    }
                }
                StudioPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        StudioSectionHeader(
                            "联网大模型配置",
                            subtitle: "DeepSeek API key 用于创造音色增强、对话改写等联网辅助能力；TTS 推理仍然走本地模型。"
                        )
                        DeepSeekConfigurationPanel(subtitle: "API key 只保存到当前 workspace 的本地配置文件；留空保存会清除本地 key。")
                        Text(viewModel.paths.deepSeekConfig.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(StudioTheme.pagePadding)
        }
        .background(StudioTheme.workspaceBackground)
        .onAppear {
            viewModel.refreshDeepSeekConfiguration()
        }
    }
}
