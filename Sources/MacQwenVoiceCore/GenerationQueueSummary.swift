public struct GenerationQueueSummary: Equatable, Sendable {
    public var total: Int
    public var succeeded: Int
    public var failed: Int
    public var skipped: Int
    public var cancelled: Bool

    public init(total: Int, succeeded: Int = 0, failed: Int = 0, skipped: Int = 0, cancelled: Bool = false) {
        self.total = total
        self.succeeded = succeeded
        self.failed = failed
        self.skipped = skipped
        self.cancelled = cancelled
    }

    public var statusText: String {
        let prefix = cancelled ? "全文生成队列已取消" : "全文生成队列完成"
        return "\(prefix)：成功 \(succeeded)/\(total)，失败 \(failed)，跳过 \(skipped)"
    }
}
