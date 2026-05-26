import Foundation

public enum WorkspaceStartupPolicy {
    public static let initialStatusMessage = "正在初始化 workspace"

    public static func shouldShowManualInitBanner(workspaceReady: Bool, isInitializing: Bool) -> Bool {
        !workspaceReady && !isInitializing
    }
}
