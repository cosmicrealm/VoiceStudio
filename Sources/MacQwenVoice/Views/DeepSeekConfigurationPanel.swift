import SwiftUI

struct DeepSeekConfigurationPanel: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    var subtitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StudioSectionHeader(
                viewModel.localized(.deepSeekConfigTitle),
                subtitle: subtitle.isEmpty ? viewModel.localized(.settingsDeepSeekConfigSubtitle) : subtitle
            )
            HStack {
                SecureField(viewModel.localized(.deepSeekAPIKeyPlaceholder), text: $viewModel.deepSeekAPIKeyInput)
                    .textFieldStyle(.roundedBorder)
                Button {
                    viewModel.pasteDeepSeekAPIKeyFromPasteboard()
                } label: {
                    Label(viewModel.localized(.deepSeekPaste), systemImage: "doc.on.clipboard")
                }
                Button {
                    viewModel.saveDeepSeekAPIKeyFromInput()
                } label: {
                    Label(viewModel.localized(.deepSeekSaveKey), systemImage: "key")
                }
            }
            HStack {
                Label(
                    viewModel.isDeepSeekConfigured ? viewModel.localized(.deepSeekConfiguredReady) : viewModel.localized(.deepSeekNotConfigured),
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
