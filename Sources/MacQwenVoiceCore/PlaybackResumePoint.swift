import Foundation

public struct PlaybackResumePoint: Equatable, Sendable {
    public let audioID: String
    public let audioPath: String
    public let currentTime: Double
    public let duration: Double

    public init(audioID: String, audioPath: String, currentTime: Double, duration: Double) {
        self.audioID = audioID
        self.audioPath = audioPath
        self.duration = max(duration, 0)
        self.currentTime = min(max(currentTime, 0), max(duration, 0))
    }

    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }

    public func resumeTime(forAudioID candidateID: String, audioPath candidatePath: String) -> Double? {
        guard audioID == candidateID, audioPath == candidatePath else { return nil }
        guard duration > 0 else { return nil }
        guard currentTime > 0.05, currentTime < duration - 0.15 else { return nil }
        return currentTime
    }
}
