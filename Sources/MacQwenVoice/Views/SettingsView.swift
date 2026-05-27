import MacQwenVoiceCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StudioPanel {
                    HStack(alignment: .top) {
                        StudioSectionHeader(viewModel.localized(.settingsTitle), subtitle: viewModel.localized(.settingsSubtitle))
                        Spacer()
                        StudioPill(
                            title: viewModel.isDeepSeekConfigured ? viewModel.localized(.settingsDeepSeekConfigured) : viewModel.localized(.settingsDeepSeekUnconfigured),
                            systemImage: viewModel.isDeepSeekConfigured ? "checkmark.circle.fill" : "circle",
                            color: viewModel.isDeepSeekConfigured ? StudioTheme.success : .secondary
                        )
                    }
                }
                StudioPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        StudioSectionHeader(
                            viewModel.localized(.settingsInterfaceLanguageTitle),
                            subtitle: viewModel.localized(.settingsInterfaceLanguageSubtitle)
                        )
                        Picker(viewModel.localized(.settingsInterfaceLanguageTitle), selection: $viewModel.appLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        Text(viewModel.localized(.settingsInterfaceLanguageDescription))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                StudioPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        StudioSectionHeader(
                            viewModel.localized(.settingsOnlineModelConfigTitle),
                            subtitle: viewModel.localized(.settingsOnlineModelConfigSubtitle)
                        )
                        DeepSeekConfigurationPanel(subtitle: viewModel.localized(.settingsDeepSeekConfigSubtitle))
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
