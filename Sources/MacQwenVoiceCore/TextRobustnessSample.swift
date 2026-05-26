import Foundation

public struct TextRobustnessSample: Equatable, Sendable, Identifiable {
    public var id: String { title }
    public let title: String
    public let text: String

    public init(title: String, text: String) {
        self.title = title
        self.text = text
    }

    public static let defaultSamples: [TextRobustnessSample] = [
        .init(
            title: "官方中文 hard example",
            text: "Qwen-TTS 是支持音色克隆、生成、控制的开源语音合成模型，不仅支持多语言multilingual，还支持各种复杂文本，如pin1 yin1，特殊符号等(◍•͈⌔•͈◍)；能读出各种生僻字詞。快来试试吧！"
        ),
        .init(
            title: "官方英文公式 hard example",
            text: "I am solving the equation: x = [-b ± √(b²-4ac)] / 2a? Nobody can — it's a disaster (◍•͈⌔•͈◍), very sad!"
        ),
        .init(
            title: "复杂符号 hard example",
            text: "Qwen-TTS 是支持音色克隆、生成、控制的语音合成模型，不仅支持多语言multilingual，还支持各种复杂文本，如pin1 yin1，特殊符号等·〛』］；能读出各种生僻字词。快来试试吧！"
        ),
        .init(
            title: "复杂标点",
            text: "今天的 ROI 是 12.5%，但 NPV 仍然为负；这说明什么？"
        ),
        .init(
            title: "拼音混排",
            text: "重庆火锅很好吃，拼音可以写作 Chongqing huoguo，也可以测试 pin1 yin1 标注。"
        ),
        .init(
            title: "公式读法",
            text: "当 x = 2 时，f(x)=x^2+3x+1 的结果是 11；如果 Δ=b²-4ac，小于 0 时没有实数根。"
        ),
        .init(
            title: "跨语言",
            text: "这是一句中文，然后切换到 English narration with a calm tone，再说一句日语：今日は良い天気です。"
        ),
        .init(
            title: "数字单位",
            text: "这台 Mac 的内存是 64GB，模型大小约 3.1 GiB，下载速度是 12.8 MB/s。"
        ),
        .init(
            title: "日期时间",
            text: "会议从 2026 年 5 月 25 日 10:30 开始，预计 11:45 结束。"
        ),
        .init(
            title: "网址邮箱",
            text: "请访问 https://qwen.ai/blog?id=qwen3tts-0115，或发送邮件到 voice-studio@example.com。"
        ),
        .init(
            title: "括号引号",
            text: "他说：“这不是 demo，而是创作者工作台。”随后补充（请保持语气自然）。"
        )
    ]
}
