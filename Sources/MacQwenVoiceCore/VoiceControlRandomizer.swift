import Foundation

public enum VoiceControlRandomizer {
    public static func randomizedProfile<T: RandomNumberGenerator>(
        workflow: ScriptStudioWorkflow,
        using generator: inout T
    ) -> VoiceControlProfile {
        var profile = VoiceControlProfile()
        for definition in VoiceControlAttributeCatalog.definitions(for: workflow) {
            let candidates = candidates(for: definition, workflow: workflow)
            guard let value = candidates.randomElement(using: &generator) else {
                continue
            }
            profile.set(value, for: definition.id)
        }
        return profile
    }

    public static func randomizedProfile(workflow: ScriptStudioWorkflow) -> VoiceControlProfile {
        var generator = SystemRandomNumberGenerator()
        return randomizedProfile(workflow: workflow, using: &generator)
    }

    public static func candidates(
        for definition: VoiceControlAttributeDefinition,
        workflow: ScriptStudioWorkflow
    ) -> [String] {
        VoiceControlAttributeCatalog.candidates(for: definition.id, workflow: workflow)
    }
}

extension VoiceControlProfile {
    public mutating func set(_ value: String, for id: VoiceControlAttributeID) {
        switch id {
        case .roleName: roleName = value
        case .language: language = value
        case .dialect: dialect = value
        case .age: age = value
        case .genderPresentation: genderPresentation = value
        case .pitch: pitch = value
        case .speed: speed = value
        case .volume: volume = value
        case .clarity: clarity = value
        case .fluency: fluency = value
        case .accent: accent = value
        case .emotion: emotion = value
        case .tone: tone = value
        case .persona: persona = value
        case .acousticTexture: acousticTexture = value
        case .humanLikeness: humanLikeness = value
        case .background: background = value
        case .gradient: gradient = value
        case .negativePrompt: negativePrompt = value
        case .customPrompt: customPrompt = value
        }
    }

    public func value(for id: VoiceControlAttributeID) -> String {
        switch id {
        case .roleName: roleName
        case .language: language
        case .dialect: dialect
        case .age: age
        case .genderPresentation: genderPresentation
        case .pitch: pitch
        case .speed: speed
        case .volume: volume
        case .clarity: clarity
        case .fluency: fluency
        case .accent: accent
        case .emotion: emotion
        case .tone: tone
        case .persona: persona
        case .acousticTexture: acousticTexture
        case .humanLikeness: humanLikeness
        case .background: background
        case .gradient: gradient
        case .negativePrompt: negativePrompt
        case .customPrompt: customPrompt
        }
    }
}
