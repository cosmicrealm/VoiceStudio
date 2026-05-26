public struct GenerationQueueMergePlan: Equatable, Sendable {
    public var paths: [String]
    public var outputName: String
    public var gapSeconds: Double

    public init(paths: [String], outputName: String, gapSeconds: Double = 0) {
        self.paths = paths
        self.outputName = outputName
        self.gapSeconds = max(0, gapSeconds)
    }
}

public enum GenerationQueueMergePlanner {
    public static func plan(
        summary: GenerationQueueSummary,
        orderedSegmentIDs: [String],
        audioPathsBySegmentID: [String: String],
        outputName: String,
        gapSeconds: Double = 0
    ) -> GenerationQueueMergePlan? {
        guard !summary.cancelled else { return nil }
        guard summary.failed == 0, summary.skipped == 0 else { return nil }
        guard summary.total == orderedSegmentIDs.count, summary.succeeded == summary.total else { return nil }
        let orderedPaths = orderedSegmentIDs.compactMap { segmentID -> String? in
            let path = audioPathsBySegmentID[segmentID]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return path.isEmpty ? nil : path
        }
        guard orderedPaths.count == orderedSegmentIDs.count, orderedPaths.count > 1 else { return nil }
        return GenerationQueueMergePlan(paths: orderedPaths, outputName: outputName, gapSeconds: gapSeconds)
    }
}
