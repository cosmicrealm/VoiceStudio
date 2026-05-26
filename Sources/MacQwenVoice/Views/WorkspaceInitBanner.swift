import AppKit
import MacQwenVoiceCore
import SwiftUI

struct WorkspaceInitBanner: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        HStack(spacing: 12) {
            StudioPill(
                title: viewModel.isInitializingWorkspace ? "初始化中" : "Workspace 未初始化",
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
                Label(viewModel.isInitializingWorkspace ? "正在初始化" : "使用默认 Workspace", systemImage: "checkmark.circle")
            }
            .disabled(viewModel.isInitializingWorkspace)
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([viewModel.paths.root])
            } label: {
                Label("打开位置", systemImage: "folder")
            }
        }
        .padding(.horizontal, StudioTheme.pagePadding)
        .padding(.vertical, 10)
        .background(StudioTheme.warning.opacity(0.08))
    }
}
