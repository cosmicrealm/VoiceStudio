import AppKit
import MacQwenVoiceCore
import SwiftUI

struct WorkspaceInitBanner: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        HStack(spacing: 12) {
            StudioPill(
                title: viewModel.isInitializingWorkspace ? viewModel.localized(.workspaceInitializing) : viewModel.localized(.workspaceNotInitialized),
                systemImage: viewModel.isInitializingWorkspace ? "hourglass" : "folder.badge.plus",
                color: StudioTheme.warning
            )
            Text(viewModel.paths.root.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .textSelection(.enabled)
            Spacer()
            Button {
                viewModel.initializeWorkspaceIfNeeded()
            } label: {
                Label(viewModel.isInitializingWorkspace ? viewModel.localized(.workspaceInitializing) : viewModel.localized(.workspaceUseDefault), systemImage: "checkmark.circle")
            }
            .disabled(viewModel.isInitializingWorkspace)
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([viewModel.paths.root])
            } label: {
                Label(viewModel.localized(.workspaceOpenLocation), systemImage: "folder")
            }
        }
        .padding(.horizontal, StudioTheme.pagePadding)
        .padding(.vertical, 10)
        .background(StudioTheme.warning.opacity(0.08))
    }
}
