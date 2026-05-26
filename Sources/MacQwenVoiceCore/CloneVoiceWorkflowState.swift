import Foundation

public struct CloneVoiceWorkflowState: Equatable, Sendable {
    public var name: String
    public var referenceAudioPath: String
    public var referenceText: String
    public var purpose: String
    public var duration: Double?

    public init(
        name: String,
        referenceAudioPath: String,
        referenceText: String,
        purpose: String,
        duration: Double?
    ) {
        self.name = name
        self.referenceAudioPath = referenceAudioPath
        self.referenceText = referenceText
        self.purpose = purpose
        self.duration = duration
    }

    public var canSave: Bool {
        missingRequirements.isEmpty
    }

    public var missingRequirements: [String] {
        var missing: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("音色名称")
        }
        if referenceAudioPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("参考音频")
        }
        if referenceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("参考逐字稿")
        }
        if purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("授权用途")
        }
        return missing
    }

    public var durationText: String {
        AudioDurationFormatter.displayText(duration)
    }
}
