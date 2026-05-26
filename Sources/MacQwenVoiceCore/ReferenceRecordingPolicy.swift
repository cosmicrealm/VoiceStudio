import Foundation

public enum ReferenceRecordingFormatPolicy {
    public static let fallbackSampleRate = 48_000.0
    public static let safeRecorderSampleRate = 48_000.0

    public static func sanitizedSampleRate(_ sampleRate: Double) -> Double {
        guard sampleRate.isFinite, sampleRate >= 16_000, sampleRate <= 96_000 else {
            return fallbackSampleRate
        }
        return sampleRate
    }
}

public struct RecordingFileStabilityPolicy: Equatable, Sendable {
    public let minimumBytes: Int64
    public let stableSampleCount: Int

    public init(minimumBytes: Int64 = 4_096, stableSampleCount: Int = 2) {
        self.minimumBytes = minimumBytes
        self.stableSampleCount = max(stableSampleCount, 1)
    }

    public func isReady(recentSizes: [Int64]) -> Bool {
        guard recentSizes.count >= stableSampleCount else { return false }
        let suffix = recentSizes.suffix(stableSampleCount)
        guard let last = suffix.last, last >= minimumBytes else { return false }
        return suffix.allSatisfy { $0 == last }
    }
}
