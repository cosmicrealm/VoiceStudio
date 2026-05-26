import Foundation

public struct VoiceLibraryGrouping: Equatable, Sendable {
    public let builtin: [VoiceProfile]
    public let clonedCustom: [VoiceProfile]
    public let designedCustom: [VoiceProfile]
    public let custom: [VoiceProfile]

    public init(voices: [VoiceProfile]) {
        builtin = voices.filter { $0.kind == .customVoice }
        clonedCustom = voices.filter { $0.kind == .clonedVoice }
        designedCustom = voices.filter { $0.kind == .voiceDesign }
        custom = clonedCustom + designedCustom
    }
}

public enum VoiceSourceSelection: String, Codable, Equatable, Sendable, CaseIterable {
    case builtin
    case custom

    public static func source(for voice: VoiceProfile?) -> VoiceSourceSelection {
        guard let voice else { return .builtin }
        return voice.kind == .customVoice ? .builtin : .custom
    }

    public static func builtinSelectedID(selectedVoiceID: String?, voices: [VoiceProfile]) -> String? {
        guard let selectedVoiceID else { return nil }
        return voices.contains { $0.id == selectedVoiceID && $0.kind == .customVoice } ? selectedVoiceID : nil
    }

    public static func customSelectedID(selectedVoiceID: String?, voices: [VoiceProfile]) -> String? {
        guard let selectedVoiceID else { return nil }
        return voices.contains { $0.id == selectedVoiceID && ($0.kind == .clonedVoice || $0.kind == .voiceDesign) } ? selectedVoiceID : nil
    }
}

public enum CustomVoiceNameAvailability {
    public static func isAvailable(
        _ name: String,
        voices: [VoiceProfile],
        excludingVoiceID: String? = nil
    ) -> Bool {
        let candidate = normalized(name)
        guard !candidate.isEmpty else { return false }
        return !voices.contains { voice in
            guard voice.kind == .clonedVoice || voice.kind == .voiceDesign else { return false }
            if let excludingVoiceID, voice.id == excludingVoiceID { return false }
            return normalized(voice.name) == candidate
        }
    }

    public static let duplicateMessage = "音色名称已存在，请换一个名称再保存"

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public enum VoiceDesignSaveNameValidationState: Equatable, Sendable {
    case empty
    case duplicate
    case available

    public var message: String? {
        switch self {
        case .empty:
            return "音色名称不能为空"
        case .duplicate:
            return CustomVoiceNameAvailability.duplicateMessage
        case .available:
            return nil
        }
    }

    public var canSave: Bool {
        self == .available
    }
}

public enum VoiceDesignSaveNameValidation {
    public static func state(for name: String, voices: [VoiceProfile]) -> VoiceDesignSaveNameValidationState {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .empty
        }
        return CustomVoiceNameAvailability.isAvailable(name, voices: voices) ? .available : .duplicate
    }
}

public struct SegmentResultState: Equatable, Sendable {
    public let audioPath: String?
    public let error: String?

    public init(audioPath: String?, error: String?) {
        self.audioPath = audioPath
        self.error = error
    }

    public var primaryActionTitle: String {
        hasResult ? "重新生成" : "生成"
    }

    public var hasResult: Bool {
        !(audioPath ?? "").isEmpty || !(error ?? "").isEmpty
    }

    public var canPlay: Bool {
        !(audioPath ?? "").isEmpty
    }
}
