import Foundation

public struct GenerationProgressEstimate: Equatable, Sendable {
    public let value: Double
    public let label: String

    public init(value: Double, label: String) {
        self.value = min(max(value, 0), 0.92)
        self.label = label
    }
}

public enum GenerationProgressEstimator {
    public static func estimatedTTSProgress(elapsedSeconds: TimeInterval) -> GenerationProgressEstimate {
        switch elapsedSeconds {
        case ..<0.8:
            return GenerationProgressEstimate(value: 0.08 + elapsedSeconds * 0.08, label: "启动 Python 后端")
        case ..<3.0:
            return GenerationProgressEstimate(value: 0.18 + (elapsedSeconds - 0.8) / 2.2 * 0.24, label: "加载 MLX 模型")
        case ..<5.0:
            return GenerationProgressEstimate(value: 0.42 + (elapsedSeconds - 3.0) / 2.0 * 0.18, label: "准备 tokenizer / speaker")
        case ..<12.0:
            return GenerationProgressEstimate(value: 0.60 + (elapsedSeconds - 5.0) / 7.0 * 0.22, label: "生成音频采样")
        default:
            let tail = 0.82 + log(elapsedSeconds - 11.0) * 0.03
            return GenerationProgressEstimate(value: tail, label: "写入 WebM / 等待返回")
        }
    }
}
