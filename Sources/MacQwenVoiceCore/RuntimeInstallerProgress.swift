import Foundation

public struct RuntimeInstallerProgress: Equatable {
    public let currentStep: Int
    public let totalSteps: Int
    public let message: String

    public var fraction: Double {
        guard totalSteps > 0 else { return 0 }
        return min(max(Double(currentStep) / Double(totalSteps), 0), 1)
    }

    public static func parse(line: String) -> RuntimeInstallerProgress? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = "VOICE_STUDIO_STEP "
        guard trimmed.hasPrefix(prefix) else { return nil }
        let rest = String(trimmed.dropFirst(prefix.count))
        guard let firstSpace = rest.firstIndex(where: { $0 == " " || $0 == "\t" }) else { return nil }
        let ratio = rest[..<firstSpace]
        let message = rest[firstSpace...].trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = ratio.split(separator: "/", maxSplits: 1)
        guard parts.count == 2,
              let current = Int(parts[0]),
              let total = Int(parts[1]),
              current >= 0,
              total > 0
        else {
            return nil
        }
        return RuntimeInstallerProgress(currentStep: current, totalSteps: total, message: message)
    }
}
