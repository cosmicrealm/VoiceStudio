import Foundation

public struct GenerationResultsPagination: Equatable, Sendable {
    public let totalItems: Int
    public let pageSize: Int
    public let currentPage: Int

    public init(totalItems: Int, pageSize: Int, currentPage: Int) {
        self.totalItems = max(0, totalItems)
        self.pageSize = max(1, pageSize)
        let totalPages = max(1, Int(ceil(Double(max(0, totalItems)) / Double(max(1, pageSize)))))
        self.currentPage = min(max(currentPage, 1), totalPages)
    }

    public var totalPages: Int {
        max(1, Int(ceil(Double(totalItems) / Double(pageSize))))
    }

    public var itemRange: Range<Int> {
        guard totalItems > 0 else { return 0..<0 }
        let start = min((currentPage - 1) * pageSize, totalItems)
        let end = min(start + pageSize, totalItems)
        return start..<end
    }

    public func visiblePageNumbers(maxVisible: Int) -> [Int] {
        let visibleCount = max(1, maxVisible)
        guard totalPages > visibleCount else {
            return Array(1...totalPages)
        }

        let halfWindow = visibleCount / 2
        var start = currentPage - halfWindow
        var end = start + visibleCount - 1

        if start < 1 {
            start = 1
            end = visibleCount
        }
        if end > totalPages {
            end = totalPages
            start = totalPages - visibleCount + 1
        }
        return Array(start...end)
    }
}
