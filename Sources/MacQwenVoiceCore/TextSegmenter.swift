import Foundation

public struct TextSegmenter: Sendable {
    public let maxCharacters: Int

    public init(maxCharacters: Int = 420) {
        self.maxCharacters = max(1, maxCharacters)
    }

    public func segments(from text: String) -> [TextSegment] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let paragraphs = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var output: [TextSegment] = []
        for paragraph in paragraphs {
            for chunk in chunks(paragraph) {
                output.append(TextSegment(index: output.count, text: chunk))
            }
        }
        return output
    }

    private func chunks(_ paragraph: String) -> [String] {
        guard paragraph.count > maxCharacters else { return [paragraph] }

        let sentences = sentenceUnits(from: paragraph)
        if sentences.count > 1 {
            var result: [String] = []
            var current = ""
            for sentence in sentences {
                if sentence.count > maxCharacters {
                    if !current.isEmpty {
                        result.append(current)
                        current = ""
                    }
                    result.append(contentsOf: hardChunks(sentence))
                } else if current.isEmpty {
                    current = sentence
                } else if current.count + sentence.count <= maxCharacters {
                    current += sentence
                } else {
                    result.append(current)
                    current = sentence
                }
            }
            if !current.isEmpty {
                result.append(current)
            }
            return result
        }

        return hardChunks(paragraph)
    }

    private func sentenceUnits(from paragraph: String) -> [String] {
        var units: [String] = []
        var current = ""
        let delimiters: Set<Character> = ["。", "！", "？", "；", "，", ".", "!", "?", ";", ","]
        for character in paragraph {
            current.append(character)
            if delimiters.contains(character) {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    units.append(trimmed)
                }
                current = ""
            }
        }
        let tail = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            units.append(tail)
        }
        return units
    }

    private func hardChunks(_ paragraph: String) -> [String] {
        var result: [String] = []
        var remaining = paragraph[...]
        while !remaining.isEmpty {
            let end = remaining.index(
                remaining.startIndex,
                offsetBy: min(maxCharacters, remaining.count)
            )
            let chunk = String(remaining[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                result.append(chunk)
            }
            remaining = remaining[end...]
        }
        return result
    }
}
