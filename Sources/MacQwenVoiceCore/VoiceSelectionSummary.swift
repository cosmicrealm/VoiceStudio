import Foundation

public enum VoiceSelectionSummary {
    public static func countLabel(selectedCount: Int, totalCount: Int) -> String {
        let safeSelectedCount = max(0, selectedCount)
        let safeTotalCount = max(0, totalCount)
        if safeSelectedCount == 0 {
            return "未选择 / 共 \(safeTotalCount)"
        }
        return "已选 \(safeSelectedCount) / 共 \(safeTotalCount)"
    }

    public static func namesSummary(_ names: [String], limit: Int = 3) -> String {
        let cleanedNames = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !cleanedNames.isEmpty else {
            return "展开后勾选要用于对话的创造音色"
        }
        let prefix = cleanedNames.prefix(max(1, limit)).joined(separator: "、")
        if cleanedNames.count > max(1, limit) {
            return "\(prefix) 等 \(cleanedNames.count) 个"
        }
        return prefix
    }
}
