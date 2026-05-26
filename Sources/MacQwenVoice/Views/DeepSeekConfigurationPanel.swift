import SwiftUI

struct DeepSeekConfigurationPanel: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    var subtitle: String = "可选联网增强；结果会先进入候选区，确认后再应用。"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StudioSectionHeader("DeepSeek 配置", subtitle: subtitle)
            HStack {
                SecureField("DeepSeek API key", text: $viewModel.deepSeekAPIKeyInput)
                    .textFieldStyle(.roundedBorder)
                Button {
                    viewModel.pasteDeepSeekAPIKeyFromPasteboard()
                } label: {
                    Label("粘贴", systemImage: "doc.on.clipboard")
                }
                Button {
                    viewModel.saveDeepSeekAPIKeyFromInput()
                } label: {
                    Label("保存 Key", systemImage: "key")
                }
            }
            HStack {
                Label(
                    viewModel.isDeepSeekConfigured ? "已配置，可联网增强" : "未配置",
                    systemImage: viewModel.isDeepSeekConfigured ? "checkmark.circle.fill" : "circle"
                )
                .foregroundStyle(viewModel.isDeepSeekConfigured ? StudioTheme.success : .secondary)
                Spacer()
            }
        }
        .padding(10)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }
}
