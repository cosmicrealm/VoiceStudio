import MacQwenVoiceCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    @State private var selectedSection: WorkspaceSection

    init() {
        let rawSection = ProcessInfo.processInfo.environment["MACQWENVOICE_INITIAL_SECTION"] ?? ""
        let initialSection = WorkspaceSection(rawValue: rawSection) ?? .scriptStudio
        _selectedSection = State(initialValue: initialSection)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailView
                .background(StudioTheme.workspaceBackground)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(VoiceStudioDefaults.appDisplayName)
                    .font(.title3.weight(.semibold))
                Text(viewModel.localized(.appTagline))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 26)
            .padding(.trailing, 18)
            .padding(.top, 18)

            VStack(spacing: 4) {
                ForEach(WorkspaceSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label {
                            Text(section.title(language: viewModel.effectiveAppLanguage))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                                .truncationMode(.tail)
                        } icon: {
                            Image(systemName: section.systemImage)
                                .frame(width: 18)
                        }
                        .font(.system(size: 14, weight: selectedSection == section ? .semibold : .regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .padding(.trailing, 12)
                        .padding(.vertical, 9)
                        .background(selectedSection == section ? Color.accentColor.opacity(0.14) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedSection == section ? Color.accentColor : .primary)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            RuntimeStatusPill()
                .padding(.leading, 26)
                .padding(.trailing, 18)
                .padding(.bottom, 16)
        }
        .frame(width: 250)
        .background(StudioTheme.panelBackground)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .scriptStudio:
            ScriptStudioView {
                selectedSection = .voiceDesign
            }
        case .premiumVoices:
            PremiumVoicesView {
                selectedSection = .scriptStudio
            }
        case .clonedVoices:
            ClonedVoicesView {
                selectedSection = .scriptStudio
            }
        case .voiceDesign:
            VoiceDesignView(
                onOpenScriptStudio: {
                    selectedSection = .scriptStudio
                },
                onOpenSettings: {
                    selectedSection = .settings
                }
            )
        case .textRobustness:
            TextRobustnessView {
                selectedSection = .scriptStudio
            }
        case .scriptRewrite:
            ScriptRewriteView(
                onOpenScriptStudio: {
                    selectedSection = .scriptStudio
                },
                onOpenSettings: {
                    selectedSection = .settings
                }
            )
        case .voiceTools:
            VoiceToolsView()
        case .models:
            ModelRuntimeView()
        case .settings:
            SettingsView()
        }
    }
}
