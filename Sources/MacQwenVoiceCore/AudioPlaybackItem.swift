import Foundation

public struct AudioPlaybackItem: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String
    public var path: String

    public init(id: String, path: String) {
        self.id = id
        self.path = path
    }

    public static func file(path: String, context: String) -> AudioPlaybackItem {
        AudioPlaybackItem(id: "\(context):\(path)", path: path)
    }
}
