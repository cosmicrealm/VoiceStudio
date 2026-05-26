import Foundation

public enum ModelScale: String, Codable, Equatable, Sendable {
    case lite06B = "0.6B"
    case pro17B = "1.7B"
}

public enum ModelVariant: String, Codable, Equatable, Sendable {
    case base = "Base"
    case customVoice = "CustomVoice"
    case voiceDesign = "VoiceDesign"
}

public enum ModelCapability: String, Codable, Equatable, Sendable {
    case voiceClone
    case customVoice
    case voiceDesign
}

public enum ModelBundle: String, Codable, Equatable, Sendable {
    case lite
    case pro
    case advanced
}

public struct QwenModelSpec: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let repository: String
    public let scale: ModelScale
    public let variant: ModelVariant
    public let capability: ModelCapability
    public let quantization: String
    public let bundle: ModelBundle
    public let estimatedSize: String
    public let sourceURL: URL

    public init(
        id: String,
        displayName: String,
        repository: String,
        scale: ModelScale,
        variant: ModelVariant,
        capability: ModelCapability,
        quantization: String,
        bundle: ModelBundle,
        estimatedSize: String,
        sourceURL: URL
    ) {
        self.id = id
        self.displayName = displayName
        self.repository = repository
        self.scale = scale
        self.variant = variant
        self.capability = capability
        self.quantization = quantization
        self.bundle = bundle
        self.estimatedSize = estimatedSize
        self.sourceURL = sourceURL
    }
}

public struct ModelPrecisionChoice: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let repository: String
    public let detail: String

    public init(id: String, title: String, repository: String, detail: String) {
        self.id = id
        self.title = title
        self.repository = repository
        self.detail = detail
    }

    public func localPath(in paths: AppPaths) -> String {
        paths.models
            .appendingPathComponent(repository.replacingOccurrences(of: "/", with: "__"), isDirectory: true)
            .path
    }
}

public extension QwenModelSpec {
    var precisionChoices: [ModelPrecisionChoice] {
        guard id == "qwen3-tts-12hz-1.7b-voicedesign" else {
            return []
        }
        return [
            ModelPrecisionChoice(
                id: "8bit",
                title: "8bit 量化",
                repository: "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit",
                detail: "更省内存，适合作为默认 VoiceDesign 预览。"
            ),
            ModelPrecisionChoice(
                id: "bf16",
                title: "bf16 原精度",
                repository: "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16",
                detail: "更接近原始精度，适合排查量化差异；内存压力更高。"
            )
        ]
    }

    func resolvedDisplayName(localPath: String?) -> String {
        guard
            let localPath,
            !localPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let choice = precisionChoices.first(where: { precisionChoice in
                localPathMatchesRepository(localPath, repository: precisionChoice.repository)
            })
        else {
            return displayName
        }
        return displayName.replacingOccurrences(of: quantization, with: choice.id)
    }

    private func localPathMatchesRepository(_ localPath: String, repository: String) -> Bool {
        let expectedDirectoryName = repository.replacingOccurrences(of: "/", with: "__")
        let path = URL(fileURLWithPath: localPath).standardizedFileURL.path
        return path == expectedDirectoryName || path.hasSuffix("/\(expectedDirectoryName)")
    }
}

public struct ModelCatalog: Sendable {
    public let models: [QwenModelSpec]

    public init(models: [QwenModelSpec]) {
        self.models = models
    }

    public var liteBundle: [QwenModelSpec] {
        models.filter { $0.bundle == .lite }
    }

    public var proBundle: [QwenModelSpec] {
        models.filter { $0.bundle == .pro }
    }

    public var advancedBundle: [QwenModelSpec] {
        models.filter { $0.bundle == .advanced }
    }

    public var baseModels: [QwenModelSpec] {
        models.filter { $0.variant == .base }
    }

    public var customVoiceModels: [QwenModelSpec] {
        models.filter { $0.variant == .customVoice }
    }

    public var voiceDesignModels: [QwenModelSpec] {
        models.filter { $0.variant == .voiceDesign }
    }

    public var scriptStudioGenerationModels: [QwenModelSpec] {
        models
    }

    public func models(forWorkflow workflow: ScriptStudioWorkflow) -> [QwenModelSpec] {
        models(for: workflow.modelCapability)
    }

    public func models(for capability: ModelCapability) -> [QwenModelSpec] {
        models.filter { $0.capability == capability }
    }

    public func preferredModelID(
        forWorkflow workflow: ScriptStudioWorkflow,
        selectedModelID: String,
        readyModelIDs: Set<String>
    ) -> String {
        let compatibleModels = models(forWorkflow: workflow)
        if compatibleModels.contains(where: { $0.id == selectedModelID }) {
            return selectedModelID
        }
        if let ready = compatibleModels.first(where: { readyModelIDs.contains($0.id) }) {
            return ready.id
        }
        return compatibleModels.first(where: { $0.bundle == .lite })?.id
            ?? compatibleModels.first?.id
            ?? selectedModelID
    }

    public func preferredModelID(
        for capability: ModelCapability,
        selectedModelID: String,
        readyModelIDs: Set<String>
    ) -> String {
        let compatibleModels = models(for: capability)
        if compatibleModels.contains(where: { $0.id == selectedModelID }) {
            return selectedModelID
        }
        if let ready = compatibleModels.first(where: { readyModelIDs.contains($0.id) }) {
            return ready.id
        }
        return compatibleModels.first(where: { $0.bundle == .lite })?.id
            ?? compatibleModels.first?.id
            ?? selectedModelID
    }

    public static let `default` = ModelCatalog(models: [
        QwenModelSpec(
            id: "qwen3-tts-12hz-0.6b-customvoice",
            displayName: "Qwen3-TTS 0.6B CustomVoice 8bit",
            repository: "mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-8bit",
            scale: .lite06B,
            variant: .customVoice,
            capability: .customVoice,
            quantization: "8bit",
            bundle: .lite,
            estimatedSize: "~0.5B params",
            sourceURL: URL(string: "https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-0.6B-CustomVoice-8bit")!
        ),
        QwenModelSpec(
            id: "qwen3-tts-12hz-0.6b-base",
            displayName: "Qwen3-TTS 0.6B Base 8bit",
            repository: "mlx-community/Qwen3-TTS-12Hz-0.6B-Base-8bit",
            scale: .lite06B,
            variant: .base,
            capability: .voiceClone,
            quantization: "8bit",
            bundle: .lite,
            estimatedSize: "~0.5B params",
            sourceURL: URL(string: "https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-0.6B-Base-8bit")!
        ),
        QwenModelSpec(
            id: "qwen3-tts-12hz-1.7b-customvoice",
            displayName: "Qwen3-TTS 1.7B CustomVoice 8bit",
            repository: "mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit",
            scale: .pro17B,
            variant: .customVoice,
            capability: .customVoice,
            quantization: "8bit",
            bundle: .pro,
            estimatedSize: "~0.8B params",
            sourceURL: URL(string: "https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-8bit")!
        ),
        QwenModelSpec(
            id: "qwen3-tts-12hz-1.7b-base",
            displayName: "Qwen3-TTS 1.7B Base 8bit",
            repository: "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit",
            scale: .pro17B,
            variant: .base,
            capability: .voiceClone,
            quantization: "8bit",
            bundle: .pro,
            estimatedSize: "~0.8B params",
            sourceURL: URL(string: "https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-Base-8bit")!
        ),
        QwenModelSpec(
            id: "qwen3-tts-12hz-1.7b-voicedesign",
            displayName: "Qwen3-TTS 1.7B VoiceDesign 8bit",
            repository: "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit",
            scale: .pro17B,
            variant: .voiceDesign,
            capability: .voiceDesign,
            quantization: "8bit",
            bundle: .advanced,
            estimatedSize: "~0.8B params",
            sourceURL: URL(string: "https://huggingface.co/mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit")!
        )
    ])
}
