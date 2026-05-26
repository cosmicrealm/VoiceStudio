import Foundation

public enum VoiceKind: String, Codable, Equatable, Sendable {
    case customVoice
    case clonedVoice
    case voiceDesign
}

public struct VoiceProfile: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var name: String
    public var kind: VoiceKind
    public var language: String
    public var speaker: String?
    public var instruct: String
    public var referenceAudioPath: String?
    public var referenceText: String?
    public var consentID: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        kind: VoiceKind,
        language: String,
        speaker: String? = nil,
        instruct: String = "",
        referenceAudioPath: String? = nil,
        referenceText: String? = nil,
        consentID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.language = language
        self.speaker = speaker
        self.instruct = instruct
        self.referenceAudioPath = referenceAudioPath
        self.referenceText = referenceText
        self.consentID = consentID
        self.createdAt = createdAt
    }
}

public enum ModelInstallStatus: String, Codable, Equatable, Sendable {
    case missing
    case downloading
    case ready
    case failed
}

public struct ModelState: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var localPath: String?
    public var status: ModelInstallStatus
    public var bytes: Int64?

    public init(id: String, localPath: String? = nil, status: ModelInstallStatus = .missing, bytes: Int64? = nil) {
        self.id = id
        self.localPath = localPath
        self.status = status
        self.bytes = bytes
    }
}

public struct ConsentRecord: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var audioSource: String
    public var purpose: String
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        audioSource: String,
        purpose: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.audioSource = audioSource
        self.purpose = purpose
        self.createdAt = createdAt
    }
}

public struct VoiceAsset: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var type: VoiceKind
    public var speaker: String?
    public var language: String
    public var instruct: String
    public var refAudioPath: String?
    public var refText: String?
    public var clonePromptPath: String?
    public var consentID: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        type: VoiceKind,
        speaker: String? = nil,
        language: String,
        instruct: String = "",
        refAudioPath: String? = nil,
        refText: String? = nil,
        clonePromptPath: String? = nil,
        consentID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.speaker = speaker
        self.language = language
        self.instruct = instruct
        self.refAudioPath = refAudioPath
        self.refText = refText
        self.clonePromptPath = clonePromptPath
        self.consentID = consentID
        self.createdAt = createdAt
    }
}

public struct ReferenceRecording: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var path: String
    public var duration: Double
    public var transcript: String
    public var consentID: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        path: String,
        duration: Double,
        transcript: String = "",
        consentID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.path = path
        self.duration = duration
        self.transcript = transcript
        self.consentID = consentID
        self.createdAt = createdAt
    }
}

public enum GenerationStatus: String, Codable, Equatable, Sendable {
    case ready
    case failed
    case running
}

public struct GenerationRecord: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var mode: String
    public var modelID: String
    public var voiceAssetID: String?
    public var text: String
    public var instruct: String
    public var audioPath: String
    public var runtime: String
    public var status: GenerationStatus
    public var error: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        mode: String,
        modelID: String,
        voiceAssetID: String? = nil,
        text: String,
        instruct: String = "",
        audioPath: String = "",
        runtime: String = "",
        status: GenerationStatus,
        error: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.mode = mode
        self.modelID = modelID
        self.voiceAssetID = voiceAssetID
        self.text = text
        self.instruct = instruct
        self.audioPath = audioPath
        self.runtime = runtime
        self.status = status
        self.error = error
        self.createdAt = createdAt
    }
}

public struct VoiceProject: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public var title: String
    public var rawText: String
    public var defaultVoiceID: String?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        rawText: String,
        defaultVoiceID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.defaultVoiceID = defaultVoiceID
        self.createdAt = createdAt
    }
}

public struct TextSegment: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let index: Int
    public let text: String

    public init(id: String = UUID().uuidString, index: Int, text: String) {
        self.id = id
        self.index = index
        self.text = text
    }
}
