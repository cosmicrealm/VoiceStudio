import Foundation

public struct PlaybackQueueControlState: Equatable, Sendable {
    public let isPlaying: Bool

    public init(isPlaying: Bool) {
        self.isPlaying = isPlaying
    }

    public var title: String {
        isPlaying ? "暂停全文" : "播放全文"
    }

    public var systemImage: String {
        isPlaying ? "pause.circle" : "play.circle"
    }

    public var shouldPauseOnTap: Bool {
        isPlaying
    }
}
