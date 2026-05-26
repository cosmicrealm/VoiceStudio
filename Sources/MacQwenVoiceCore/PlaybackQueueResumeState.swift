import Foundation

public struct PlaybackQueueResumePlan: Equatable, Sendable {
    public let startIndex: Int
    public let resumeTime: Double
    public let remainingPaths: [String]

    public init(startIndex: Int, resumeTime: Double, remainingPaths: [String]) {
        self.startIndex = startIndex
        self.resumeTime = resumeTime
        self.remainingPaths = remainingPaths
    }
}

public struct PlaybackQueueResumeState: Equatable, Sendable {
    public let itemIndex: Int
    public let itemPath: String
    public let currentTime: Double
    public let duration: Double

    public init(itemIndex: Int, itemPath: String, currentTime: Double, duration: Double) {
        self.itemIndex = itemIndex
        self.itemPath = itemPath
        self.duration = max(duration, 0)
        self.currentTime = min(max(currentTime, 0), max(duration, 0))
    }

    public func resumePlan(for paths: [String]) -> PlaybackQueueResumePlan? {
        guard paths.indices.contains(itemIndex), paths[itemIndex] == itemPath else { return nil }
        guard duration > 0 else { return nil }
        guard currentTime > 0.05, currentTime < duration - 0.15 else { return nil }
        return PlaybackQueueResumePlan(
            startIndex: itemIndex,
            resumeTime: currentTime,
            remainingPaths: Array(paths[itemIndex...])
        )
    }
}
