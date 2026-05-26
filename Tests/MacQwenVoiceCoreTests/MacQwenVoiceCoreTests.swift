import Foundation
import Testing
@testable import MacQwenVoiceCore

@Test func textSegmenterKeepsParagraphsAndSplitsLongText() {
    let text = """
    第一段很短。

    第二段会比较长，需要按照长度切开，避免一次生成失败影响全部音频。这里继续补充一些内容，让它超过限制。
    """

    let segments = TextSegmenter(maxCharacters: 28).segments(from: text)

    #expect(segments.count == 4)
    #expect(segments[0].text == "第一段很短。")
    #expect(segments.allSatisfy { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    #expect(segments.allSatisfy { $0.text.count <= 28 })
}

@Test func speakerTaggedTextNormalizerStripsRoleLabelsBeforeSynthesis() {
    let script = """
    旁白: 小林今天第三次走神了。
    御姐：小弟弟，有兴趣陪姐姐喝一杯吗？
    小林: 啊？我、我其实不太会喝酒。
    """

    let lines = SpeakerTaggedTextNormalizer.lines(from: script)
    let synthesisText = SpeakerTaggedTextNormalizer.synthesisText(from: script)

    #expect(lines.count == 3)
    #expect(lines[0].speaker == "旁白")
    #expect(lines[1].speaker == "御姐")
    #expect(lines[2].speaker == "小林")
    #expect(synthesisText == """
    小林今天第三次走神了。
    小弟弟，有兴趣陪姐姐喝一杯吗？
    啊？我、我其实不太会喝酒。
    """)
}

@Test func speakerTaggedTextNormalizerDropsQuotedRoleDefinitionLines() {
    let pastedDemo = """
    "旁白": "声音特征沉稳、客观、略带叙事感。"
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"

    旁白: 小林今天第三次走神了。
    小林: 我、我其实不太会喝酒。
    """

    #expect(SpeakerTaggedTextNormalizer.synthesisText(from: pastedDemo) == """
    小林今天第三次走神了。
    我、我其实不太会喝酒。
    """)
}

@Test func speakerTaggedTextNormalizerDoesNotBreakUrlsOrRatios() {
    #expect(SpeakerTaggedTextNormalizer.synthesisText(from: "https://qwen.ai/blog?id=qwen3tts-0115") == "https://qwen.ai/blog?id=qwen3tts-0115")
    #expect(SpeakerTaggedTextNormalizer.synthesisText(from: "画面比例 1:2，背景保持干净。") == "画面比例 1:2，背景保持干净。")
}

@Test func speakerTaggedTextNormalizerPreservesParagraphBreaks() {
    let text = """
    第一段。

    旁白: 第二段。
    """

    #expect(SpeakerTaggedTextNormalizer.synthesisText(from: text) == "第一段。\n\n第二段。")
}

@Test func speakerTaggedTextNormalizerBuildsRoleRoutedSegments() {
    let text = """
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"
    "御姐": "成熟磁性女性声线，沉稳自信。"

    小林: 啊？我、我其实不太会喝酒。
    御姐: 小弟弟，有兴趣陪姐姐喝一杯吗？
    """

    let script = SpeakerTaggedTextNormalizer.script(from: text)
    let segments = SpeakerTaggedTextNormalizer.synthesisSegments(from: text, maxCharacters: 420)

    #expect(script.hasRoleRouting)
    #expect(script.roleDefinitions["小林"]?.contains("男性上班族") == true)
    #expect(script.roleDefinitions["御姐"]?.contains("女性声线") == true)
    #expect(segments.map(\.speaker) == ["小林", "御姐"])
    #expect(segments.map(\.text) == ["啊？我、我其实不太会喝酒。", "小弟弟，有兴趣陪姐姐喝一杯吗？"])
    #expect(segments[0].instruction?.contains("男性上班族") == true)
    #expect(segments[1].instruction?.contains("女性声线") == true)
}

@Test func speakerTaggedTextNormalizerExtractsDialogueRoleNamesWithoutDefinitions() {
    let text = """
    旁白: 小林今天第三次走神了。
    御姐: 小弟弟，有兴趣陪姐姐喝一杯吗？
    小林: 啊？我、我其实不太会喝酒。
    旁白: 他猛地坐直，又立刻缩回肩膀。
    """

    #expect(SpeakerTaggedTextNormalizer.roleNames(from: text) == ["旁白", "御姐", "小林"])
}

@Test func speakerTaggedTextNormalizerKeepsOneRoleUtteranceAsOneLiveGenerationUnit() {
    let text = """
    "旁白": "声音特征沉稳、客观、略带叙事感的女播音腔。"

    旁白: 小林今天第三次走神了。酒吧昏黄的灯光晃得他心跳加速。
    """

    let segments = SpeakerTaggedTextNormalizer.synthesisSegments(from: text, maxCharacters: 420)

    #expect(segments.count == 1)
    #expect(segments[0].speaker == "旁白")
    #expect(segments[0].instruction == "声音特征沉稳、客观、略带叙事感的女播音腔。")
    #expect(segments[0].text == "小林今天第三次走神了。酒吧昏黄的灯光晃得他心跳加速。")
}

@Test func speakerTaggedTextNormalizerOptionallyBuildsRoleRoutedSentenceSegments() {
    let text = """
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"
    "御姐": "成熟磁性女性声线，沉稳自信。"

    小林: 啊？我、我其实不太会喝酒。真的只看了一眼。
    御姐: 不会喝？那正好。
    """

    let segments = SpeakerTaggedTextNormalizer.synthesisSegments(from: text, maxCharacters: 420, sentenceLevel: true)

    #expect(segments.map(\.speaker) == ["小林", "小林", "小林", "御姐", "御姐"])
    #expect(segments.map(\.text) == ["啊？", "我、我其实不太会喝酒。", "真的只看了一眼。", "不会喝？", "那正好。"])
    #expect(segments[0].instruction?.contains("男性上班族") == true)
    #expect(segments[3].instruction?.contains("女性声线") == true)
}

@Test func speakerTaggedTextNormalizerUsesRawRoleDefinitionAsLiveInstructionAndStableSeed() {
    let maleInstruction = SpeakerTaggedTextNormalizer.liveVoiceDesignInstruction(
        speaker: "小林",
        instruction: "25岁男性上班族，声音清亮但时常犹豫。"
    )
    let xiaoLinSeed = SpeakerTaggedTextNormalizer.deterministicSeed(
        speaker: "小林",
        instruction: "25岁男性上班族，声音清亮但时常犹豫。"
    )
    let xiaoLinSeedAgain = SpeakerTaggedTextNormalizer.deterministicSeed(
        speaker: "小林",
        instruction: "25岁男性上班族，声音清亮但时常犹豫。"
    )
    let jieSeed = SpeakerTaggedTextNormalizer.deterministicSeed(
        speaker: "御姐",
        instruction: "成熟磁性女性声线，沉稳自信。"
    )

    #expect(maleInstruction == "25岁男性上班族，声音清亮但时常犹豫。")
    #expect(xiaoLinSeed == xiaoLinSeedAgain)
    #expect(xiaoLinSeed != jieSeed)
    #expect(xiaoLinSeed > 0)
}

@Test func speakerTaggedTextNormalizerParsesRoleDefinitionTouchingFirstUtterance() {
    let text = """
    "旁白": "沉稳旁白。"
    "御姐": "成熟磁性女性声线。"旁白: 小林今天第三次走神了。
    御姐: 小弟弟，有兴趣陪姐姐喝一杯吗？
    """

    let script = SpeakerTaggedTextNormalizer.script(from: text)
    let segments = SpeakerTaggedTextNormalizer.synthesisSegments(from: text, maxCharacters: 420)

    #expect(script.roleDefinitions["御姐"] == "成熟磁性女性声线。")
    #expect(segments.map(\.speaker) == ["旁白", "御姐"])
    #expect(segments.map(\.text) == ["小林今天第三次走神了。", "小弟弟，有兴趣陪姐姐喝一杯吗？"])
}

@Test func speakerTaggedTextNormalizerBuildsOfficialTimbreReuseInputs() {
    let text = """
    "旁白": "沉稳、客观、略带叙事感的女播音腔。"
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"
    "御姐": "成熟磁性女性声线，沉稳自信。"
    旁白: 小林今天第三次走神了。
    小林: 啊？我、我其实不太会喝酒。
    """

    #expect(SpeakerTaggedTextNormalizer.roleControlInstruction(from: text) == """
    "旁白": "沉稳、客观、略带叙事感的女播音腔。"
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"
    "御姐": "成熟磁性女性声线，沉稳自信。"
    """)
    #expect(SpeakerTaggedTextNormalizer.roleRoutedText(from: text) == """
    旁白: 小林今天第三次走神了。
    小林: 啊？我、我其实不太会喝酒。
    """)
    #expect(SpeakerTaggedTextNormalizer.roleLabeledText(speaker: "小林", text: "啊？我、我其实不太会喝酒。") == "小林: 啊？我、我其实不太会喝酒。")
}

@Test func speakerTaggedTextNormalizerBuildsReusableRoleReferencesForDesignThenClone() {
    let text = """
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"
    "御姐": "成熟磁性女性声线，沉稳自信。"
    小林: 啊？我、我其实不太会喝酒。
    御姐: 小弟弟，有兴趣陪姐姐喝一杯吗？
    小林: 我没偷看，只看了一眼。
    """

    let references = SpeakerTaggedTextNormalizer.roleReferences(from: text)
    let instruction = SpeakerTaggedTextNormalizer.reusableVoiceDesignInstruction(
        speaker: "小林",
        instruction: references[0].instruction
    )

    #expect(references.map(\.speaker) == ["小林", "御姐"])
    #expect(references[0].referenceText != "啊？我、我其实不太会喝酒。")
    #expect(references[0].referenceText.contains("紧张"))
    #expect(references[0].referenceText.contains("清楚"))
    #expect(!references[0].referenceText.contains("小林:"))
    #expect(!references[0].referenceText.contains("小林："))
    #expect(references[1].instruction.contains("女性声线"))
    #expect(instruction.contains("只朗读合成文本，不朗读角色名"))
    #expect(instruction.contains("必须生成明确男性声线"))
    #expect(instruction.contains("不要生成女性声线"))
    #expect(instruction.contains("Male voice"))
}

@Test func speakerTaggedTextNormalizerBuildsOneToOneMultiRoleInputsFromSeparateInstruction() {
    let instruction = "\"小林\": \"25岁男性上班族，声音清亮但时常犹豫。\""
    let text = "啊？我、我其实不太会喝酒。"

    let script = SpeakerTaggedTextNormalizer.script(roleDefinitionsText: instruction, synthesisText: text)
    let segments = SpeakerTaggedTextNormalizer.synthesisSegments(
        roleDefinitionsText: instruction,
        synthesisText: text,
        maxCharacters: 420
    )
    let references = SpeakerTaggedTextNormalizer.roleReferences(
        roleDefinitionsText: instruction,
        synthesisText: text
    )

    #expect(script.hasRoleRouting)
    #expect(segments.count == 1)
    #expect(segments[0].speaker == "小林")
    #expect(segments[0].instruction == "25岁男性上班族，声音清亮但时常犹豫。")
    #expect(segments[0].text == "啊？我、我其实不太会喝酒。")
    #expect(references.map(\.speaker) == ["小林"])
    #expect(references[0].instruction.contains("男性上班族"))
}

@Test func speakerTaggedTextNormalizerCombinesSeparateRoleDefinitionsWithTaggedDialogue() {
    let instruction = """
    "小林": "25岁男性上班族。"
    "御姐": "成熟磁性女性声线。"
    """
    let text = """
    御姐: 小弟弟，有兴趣陪姐姐喝一杯吗？
    小林: 啊？我、我其实不太会喝酒。
    """

    let segments = SpeakerTaggedTextNormalizer.synthesisSegments(
        roleDefinitionsText: instruction,
        synthesisText: text,
        maxCharacters: 420
    )

    #expect(segments.map(\.speaker) == ["御姐", "小林"])
    #expect(segments.map(\.text) == ["小弟弟，有兴趣陪姐姐喝一杯吗？", "啊？我、我其实不太会喝酒。"])
    #expect(segments[0].instruction == "成熟磁性女性声线。")
    #expect(segments[1].instruction == "25岁男性上班族。")
}

@Test func modelCatalogMarksLiteAndProBundles() {
    let catalog = ModelCatalog.default

    #expect(catalog.models.count == 5)
    #expect(catalog.liteBundle.map(\.id) == ["qwen3-tts-12hz-0.6b-customvoice", "qwen3-tts-12hz-0.6b-base"])
    #expect(catalog.proBundle.map(\.id) == ["qwen3-tts-12hz-1.7b-customvoice", "qwen3-tts-12hz-1.7b-base"])
    #expect(catalog.models.first { $0.capability == .voiceClone }?.variant == .base)
}

@Test func modelCatalogExposesBaseModelsForCloneWorkflow() {
    let catalog = ModelCatalog.default

    #expect(catalog.baseModels.map(\.id) == [
        "qwen3-tts-12hz-0.6b-base",
        "qwen3-tts-12hz-1.7b-base"
    ])
    #expect(catalog.baseModels.allSatisfy { $0.capability == .voiceClone })
    #expect(catalog.models(forWorkflow: .multiRole).map(\.id) == catalog.baseModels.map(\.id))
}

@Test func modelCatalogExposesScriptStudioGenerationModelsButKeepsVoiceDesignSeparate() {
    let catalog = ModelCatalog.default

    #expect(catalog.scriptStudioGenerationModels.map(\.id) == [
        "qwen3-tts-12hz-0.6b-customvoice",
        "qwen3-tts-12hz-0.6b-base",
        "qwen3-tts-12hz-1.7b-customvoice",
        "qwen3-tts-12hz-1.7b-base",
        "qwen3-tts-12hz-1.7b-voicedesign"
    ])
    #expect(catalog.scriptStudioGenerationModels.count == catalog.models.count)
    #expect(catalog.voiceDesignModels.map(\.id) == ["qwen3-tts-12hz-1.7b-voicedesign"])
}

@Test func modelCatalogExposesVoiceDesignPrecisionChoices() {
    let model = ModelCatalog.default.voiceDesignModels[0]
    let root = URL(fileURLWithPath: "/tmp/VoiceStudioWorkspace", isDirectory: true)
    let paths = AppPaths(root: root)

    #expect(model.precisionChoices.map(\.id) == ["8bit", "bf16"])
    #expect(model.precisionChoices.map(\.repository) == [
        "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit",
        "mlx-community/Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16"
    ])
    #expect(model.precisionChoices[0].localPath(in: paths).hasSuffix("models/mlx-community__Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit"))
    #expect(model.precisionChoices[1].localPath(in: paths).hasSuffix("models/mlx-community__Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16"))
    #expect(model.resolvedDisplayName(localPath: model.precisionChoices[0].localPath(in: paths)) == "Qwen3-TTS 1.7B VoiceDesign 8bit")
    #expect(model.resolvedDisplayName(localPath: model.precisionChoices[1].localPath(in: paths)) == "Qwen3-TTS 1.7B VoiceDesign bf16")
    #expect(ModelCatalog.default.baseModels.allSatisfy { $0.precisionChoices.isEmpty })
    #expect(ModelCatalog.default.customVoiceModels.allSatisfy { $0.precisionChoices.isEmpty })
}

@Test func modelStateReconciliationKeepsPersistedPrecisionPathOverRuntimeDefaultProbe() {
    let modelID = "qwen3-tts-12hz-1.7b-voicedesign"
    let storedPath = "/tmp/VoiceStudioWorkspace/models/mlx-community__Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16"
    let runtimeDefaultPath = "/tmp/VoiceStudioWorkspace/models/mlx-community__Qwen3-TTS-12Hz-1.7B-VoiceDesign-8bit"
    let storedState = ModelState(id: modelID, localPath: storedPath, status: .ready, bytes: nil)

    #expect(
        ModelStateReconciliation.shouldPersistRuntimeReadyPath(
            current: nil,
            stored: storedState,
            runtimePath: runtimeDefaultPath
        ) == false
    )
    #expect(
        ModelStateReconciliation.shouldPersistRuntimeReadyPath(
            current: storedState,
            stored: nil,
            runtimePath: runtimeDefaultPath
        ) == false
    )
    #expect(
        ModelStateReconciliation.shouldPersistRuntimeReadyPath(
            current: nil,
            stored: nil,
            runtimePath: runtimeDefaultPath
        ) == true
    )
}

@Test func modelCatalogFiltersAndResolvesCompatibleGenerationModels() {
    let catalog = ModelCatalog.default

    #expect(catalog.models(for: .customVoice).map(\.id) == [
        "qwen3-tts-12hz-0.6b-customvoice",
        "qwen3-tts-12hz-1.7b-customvoice"
    ])
    #expect(
        catalog.preferredModelID(
            for: .customVoice,
            selectedModelID: "qwen3-tts-12hz-1.7b-customvoice",
            readyModelIDs: ["qwen3-tts-12hz-0.6b-customvoice"]
        ) == "qwen3-tts-12hz-1.7b-customvoice"
    )
    #expect(
        catalog.preferredModelID(
            for: .customVoice,
            selectedModelID: "qwen3-tts-12hz-0.6b-base",
            readyModelIDs: ["qwen3-tts-12hz-0.6b-customvoice"]
        ) == "qwen3-tts-12hz-0.6b-customvoice"
    )
    #expect(
        catalog.preferredModelID(
            for: .voiceClone,
            selectedModelID: "qwen3-tts-12hz-1.7b-voicedesign",
            readyModelIDs: []
        ) == "qwen3-tts-12hz-0.6b-base"
    )
}

@Test func scriptStudioWorkflowsRouteToModelFamiliesInsteadOfFlatModelChoices() {
    let catalog = ModelCatalog.default

    #expect(catalog.models(forWorkflow: .builtin).map(\.id) == [
        "qwen3-tts-12hz-0.6b-customvoice",
        "qwen3-tts-12hz-1.7b-customvoice"
    ])
    #expect(catalog.models(forWorkflow: .custom).map(\.id) == [
        "qwen3-tts-12hz-0.6b-base",
        "qwen3-tts-12hz-1.7b-base"
    ])
    #expect(catalog.models(forWorkflow: .voiceDesign).map(\.id) == [
        "qwen3-tts-12hz-1.7b-voicedesign"
    ])

    #expect(
        catalog.preferredModelID(
            forWorkflow: .builtin,
            selectedModelID: "qwen3-tts-12hz-1.7b-base",
            readyModelIDs: []
        ) == "qwen3-tts-12hz-0.6b-customvoice"
    )
    #expect(
        catalog.preferredModelID(
            forWorkflow: .custom,
            selectedModelID: "qwen3-tts-12hz-1.7b-voicedesign",
            readyModelIDs: ["qwen3-tts-12hz-1.7b-base"]
        ) == "qwen3-tts-12hz-1.7b-base"
    )
    #expect(
        catalog.preferredModelID(
            forWorkflow: .voiceDesign,
            selectedModelID: "qwen3-tts-12hz-0.6b-customvoice",
            readyModelIDs: []
        ) == "qwen3-tts-12hz-1.7b-voicedesign"
    )
}

@Test func scriptStudioPromptSetSeparatesVoiceIdentityFromDeliveryStyle() {
    let promptSet = ScriptStudioPromptSet(
        deliveryStylePrompt: "自然、清晰、语速偏慢",
        voiceIdentityDescription: "30岁女性纪录片旁白，低音、沉稳、轻微气声"
    )

    #expect(promptSet.activePrompt(for: .builtin) == "自然、清晰、语速偏慢")
    #expect(promptSet.activePrompt(for: .custom) == "自然、清晰、语速偏慢")
    #expect(promptSet.activePrompt(for: .voiceDesign) == "30岁女性纪录片旁白，低音、沉稳、轻微气声")
    #expect(promptSet.activePrompt(for: .multiRole) == "自然、清晰、语速偏慢")
    #expect(promptSet.missingRequirement(for: .voiceDesign) == nil)
    #expect(promptSet.missingRequirement(for: .multiRole) == nil)

    let emptyDesign = ScriptStudioPromptSet(deliveryStylePrompt: "自然", voiceIdentityDescription: "  ")
    #expect(emptyDesign.missingRequirement(for: .voiceDesign) == "控制指令")
}

@Test func scriptStudioWorkflowExposesMultiRoleAsDesignThenCloneMode() {
    #expect(ScriptStudioWorkflow.allCases.map(\.title) == ["精品生成", "克隆生成", "创造生成", "对话生成"])
    #expect(ScriptStudioWorkflow.multiRole.modelCapability == .voiceClone)
}

@Test func scriptStudioWorkflowRefreshPreservesManualGenerationModes() {
    #expect(ScriptStudioWorkflow.normalizedAfterVoiceLibraryRefresh(current: .multiRole, voiceSource: .builtin) == .multiRole)
    #expect(ScriptStudioWorkflow.normalizedAfterVoiceLibraryRefresh(current: .voiceDesign, voiceSource: .custom) == .voiceDesign)
    #expect(ScriptStudioWorkflow.normalizedAfterVoiceLibraryRefresh(current: .builtin, voiceSource: .custom) == .custom)
    #expect(ScriptStudioWorkflow.normalizedAfterVoiceLibraryRefresh(current: .custom, voiceSource: .builtin) == .builtin)
}

@Test func scriptStudioGenerationInputPreviewShowsActualInstructionAndText() {
    let promptSet = ScriptStudioPromptSet(
        deliveryStylePrompt: "旁白声音稳定、客观，关键情节稍作停顿。",
        voiceIdentityDescription: "30岁女性纪录片旁白，低音、沉稳、轻微气声"
    )

    let preview = ScriptStudioGenerationInputPreview(
        workflow: .builtin,
        promptSet: promptSet,
        synthesisText: "旁白：小林今天第三次走神了。",
        segmentCount: 1
    )

    #expect(preview.controlTitle == "控制指令")
    #expect(preview.synthesisTitle == "合成文本")
    #expect(preview.controlInstruction == "旁白声音稳定、客观，关键情节稍作停顿。")
    #expect(preview.synthesisText == "旁白：小林今天第三次走神了。")
    #expect(preview.caption == "生成时会将控制指令作为 instruct/prompt，并将合成文本按 1 个段落送入模型。")

    let designPreview = ScriptStudioGenerationInputPreview(
        workflow: .voiceDesign,
        promptSet: promptSet,
        synthesisText: "今天我们来讲一个复杂但有意思的技术问题。",
        segmentCount: 2
    )

    #expect(designPreview.controlInstruction == "30岁女性纪录片旁白，低音、沉稳、轻微气声")
    #expect(designPreview.caption == "生成时会将控制指令作为 instruct/prompt，并将合成文本按 2 个段落送入模型。")
}

@Test func textRobustnessSamplesIncludeOfficialHardExamples() {
    let samples = TextRobustnessSample.defaultSamples
    let titles = samples.map(\.title)

    #expect(Set(titles).count == titles.count)
    #expect(samples.contains { $0.title.contains("官方中文") && $0.text.contains("pin1 yin1") && $0.text.contains("生僻字詞") })
    #expect(samples.contains { $0.title.contains("官方英文公式") && $0.text.contains("[-b ± √(b²-4ac)] / 2a") && $0.text.contains("◍•͈⌔•͈◍") })
    #expect(samples.contains { $0.title.contains("复杂符号") && $0.text.contains("·〛』］") })
}

@Test func scriptStudioLanguageDetectorClassifiesSingleAndMixedLanguages() {
    #expect(ScriptStudioLanguageDetector.detect("这是中文旁白。") == .chinese)
    #expect(ScriptStudioLanguageDetector.detect("This is an English narration.") == .english)
    #expect(ScriptStudioLanguageDetector.detect("今日は良い天気です。") == .japanese)
    #expect(ScriptStudioLanguageDetector.detect("오늘은 날씨가 좋습니다.") == .korean)
    #expect(ScriptStudioLanguageDetector.detect("Сегодня хорошая погода.") == .russian)
    #expect(ScriptStudioLanguageDetector.detect("这是中文 and English mixed.") == .mixed)
    #expect(ScriptStudioLanguageDetector.detect("   ") == .unknown)
}

@Test func scriptStudioLanguageOptionsExposeAllQwenLanguagesInChinese() {
    #expect(ScriptStudioLanguageChoice.toggleOptions.map(\.displayTitle) == [
        "自动",
        "中文",
        "北京话",
        "四川话",
        "英文",
        "日语",
        "韩语",
        "德语",
        "法语",
        "俄语",
        "葡萄牙语",
        "西班牙语",
        "意大利语"
    ])
    #expect(ScriptStudioLanguageOption.beijingDialect.requestValue == "beijing_dialect")
    #expect(ScriptStudioLanguageOption.sichuanDialect.requestValue == "sichuan_dialect")
    #expect(ScriptStudioLanguageOption.portuguese.requestValue == "Portuguese")
    #expect(ScriptStudioLanguageOption.italian.requestValue == "Italian")
}

@Test func scriptStudioLanguageOptionsExposeDialectsOnlyForCustomVoiceWorkflow() {
    let dialects: Set<ScriptStudioLanguageOption> = [.beijingDialect, .sichuanDialect]
    #expect(dialects.isSubset(of: Set(ScriptStudioLanguageChoice.toggleOptions(for: .builtin))))

    for workflow in [ScriptStudioWorkflow.custom, .voiceDesign, .multiRole] {
        let options = Set(ScriptStudioLanguageChoice.toggleOptions(for: workflow))
        #expect(options.isDisjoint(with: dialects))
    }
}

@Test func scriptStudioModelInputPreviewDropsDialectChoiceOutsideCustomVoiceWorkflow() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .custom,
        text: "北京胡同里的风声很轻。",
        languageChoice: .beijingDialect,
        speaker: "",
        instruct: "",
        refAudioPath: "/tmp/ref.wav",
        refText: "北京胡同里的风声很轻。"
    )

    #expect(preview.languageChoice == .automatic)
    #expect(preview.requestLanguage == "Chinese")
}

@Test func scriptStudioLanguageChoiceResolvesAutoAndManualOverride() {
    #expect(ScriptStudioLanguageChoice.automatic.requestLanguage(for: "这是中文。") == "Chinese")
    #expect(ScriptStudioLanguageChoice.automatic.requestLanguage(for: "English text.") == "English")
    #expect(ScriptStudioLanguageChoice.automatic.requestLanguage(for: "中文 and English") == "Auto")
    #expect(ScriptStudioLanguageChoice.japanese.requestLanguage(for: "中文 and English") == "Japanese")
    #expect(ScriptStudioLanguageChoice.automatic.displayLabel(for: "中文 and English") == "混合")
}

@Test func scriptStudioLanguageChoiceSupportsManualLanguageCombinations() {
    let english = ScriptStudioLanguageChoice.automatic.toggled(.english)
    let chineseEnglish = english.toggled(.chinese)
    let backToAuto = chineseEnglish.toggled(.english).toggled(.chinese)

    #expect(english.selectedOptions == [.english])
    #expect(english.displayLabel(for: "中文 and English") == "英文")
    #expect(english.requestLanguage(for: "中文 and English") == "English")
    #expect(chineseEnglish.selectedOptions == [.chinese, .english])
    #expect(chineseEnglish.displayLabel(for: "中文 and English") == "中文 + 英文")
    #expect(chineseEnglish.requestLanguage(for: "中文 and English") == "Auto")
    #expect(backToAuto.selectedOptions == [.automatic])
}

@Test func scriptStudioLanguageChoiceKeepsAutoMutuallyExclusiveWithManualLanguages() {
    let manual = ScriptStudioLanguageChoice.manual([.chinese, .english, .automatic])
    let auto = manual.toggled(.automatic)

    #expect(manual.selectedOptions == [.chinese, .english])
    #expect(auto.selectedOptions == [.automatic])
    #expect(!auto.selectedOptions.contains(.chinese))
}

@Test func scriptStudioModelInputPreviewShowsCustomVoiceInputs() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .builtin,
        text: "你好，世界。",
        languageChoice: .automatic,
        speaker: "Serena",
        instruct: "温柔清晰",
        refAudioPath: "",
        refText: ""
    )

    #expect(preview.visibleFields == [.language, .instruct])
    #expect(preview.requestLanguage == "Chinese")
    #expect(preview.speaker == "Serena")
    #expect(preview.instruct == "温柔清晰")
    #expect(preview.isInstructEditable)
    #expect(preview.missingRequirements.isEmpty)
}

@Test func scriptStudioModelInputPreviewAllowsBlankCustomVoiceInstruction() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .builtin,
        text: "你好，世界。",
        languageChoice: .automatic,
        speaker: "Serena",
        instruct: VoiceStudioDefaults.defaultBuiltinControlInstruction,
        refAudioPath: "",
        refText: ""
    )

    #expect(!VoiceStudioDefaults.defaultBuiltinControlInstruction.isEmpty)
    #expect(VoiceStudioDefaults.defaultBuiltinControlInstruction.contains("阳光温暖"))
    #expect(preview.instruct == VoiceStudioDefaults.defaultBuiltinControlInstruction)
    #expect(preview.missingRequirements.isEmpty)
}

@Test func voiceDesignDefaultControlInstructionMatchesSimpleBuiltinStyle() {
    #expect(!VoiceStudioDefaults.defaultVoiceDesignControlInstruction.isEmpty)
    #expect(VoiceStudioDefaults.defaultVoiceDesignControlInstruction == VoiceStudioDefaults.defaultBuiltinControlInstruction)
    #expect(VoiceStudioDefaults.defaultVoiceDesignControlInstruction.contains("阳光温暖"))
    #expect(!VoiceStudioDefaults.defaultVoiceDesignControlInstruction.contains("纪录片"))
}

@Test func pageDraftStatesKeepEditableInputsOutsideViewLifetime() {
    var scriptStudio = ScriptStudioPageDraft()
    scriptStudio.isVoiceControlExpanded = true
    scriptStudio.isMultiRoleDesignedVoicePoolExpanded = true
    scriptStudio.generationResultsPage = 3
    scriptStudio.generationResultsJumpPageText = "3"
    #expect(scriptStudio.isVoiceControlExpanded)
    #expect(scriptStudio.isMultiRoleDesignedVoicePoolExpanded)
    #expect(scriptStudio.generationResultsPage == 3)

    var voiceDesign = VoiceDesignPageDraft()
    voiceDesign.controlInstruction = "用户编辑后的创造音色指令"
    voiceDesign.synthesisText = "用户编辑后的试听文本"
    voiceDesign.language = "English"
    voiceDesign.generatedControlInstruction = "随机生成后的控制类型结果"
    voiceDesign.deepSeekEnhancedInstruction = "DeepSeek 增强候选"
    voiceDesign.isControlExpanded = true

    let restoredVoiceDesign = voiceDesign
    #expect(restoredVoiceDesign.controlInstruction == "用户编辑后的创造音色指令")
    #expect(restoredVoiceDesign.synthesisText == "用户编辑后的试听文本")
    #expect(restoredVoiceDesign.language == "English")
    #expect(restoredVoiceDesign.generatedControlInstruction == "随机生成后的控制类型结果")
    #expect(restoredVoiceDesign.deepSeekEnhancedInstruction == "DeepSeek 增强候选")
    #expect(restoredVoiceDesign.isControlExpanded)

    var rewrite = ScriptRewritePageDraft()
    rewrite.sourceText = "原始小说片段"
    rewrite.contextSummary = "上文摘要"
    rewrite.stylePrompt = "克制、悬疑"
    rewrite.rewriteResult = DeepSeekScriptRewriteResult(
        roles: [DeepSeekScriptRewriteRole(name: "旁白", voiceHint: "沉稳")],
        scriptText: "旁白: 原始小说片段",
        warnings: []
    )
    #expect(rewrite.sourceText == "原始小说片段")
    #expect(rewrite.rewriteResult?.scriptText == "旁白: 原始小说片段")

    var tools = VoiceToolsPageDraft()
    tools.outputName = "用户指定文件名.webm"
    #expect(tools.outputName == "用户指定文件名.webm")

    var clone = ClonedVoicesPageDraft()
    clone.cloneName = "用户命名的克隆音色"
    clone.isTranscriptExamplesExpanded = true
    #expect(clone.cloneName == "用户命名的克隆音色")
    #expect(clone.isTranscriptExamplesExpanded)
}

@Test func scriptStudioModelInputPreviewShowsBaseCloneInputsAndDisablesInstruct() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .custom,
        text: "Hello from my cloned voice.",
        languageChoice: .english,
        speaker: "",
        instruct: "这条不应该传给 Base",
        refAudioPath: "/workspace/references/ref.wav",
        refText: "This is the reference transcript."
    )

    #expect(preview.visibleFields == [.language, .refAudio, .refText])
    #expect(preview.requestLanguage == "English")
    #expect(preview.refAudioPath == "/workspace/references/ref.wav")
    #expect(preview.refText == "This is the reference transcript.")
    #expect(preview.instruct.isEmpty)
    #expect(!preview.isInstructEditable)
    #expect(!preview.showsInstructionEditor)
    #expect(preview.disabledInstructReason == "Base Clone 不使用指令控制；音色来自 ref_audio + ref_text。")
    #expect(preview.missingRequirements.isEmpty)
}

@Test func scriptStudioModelInputPreviewRequiresBaseCloneReferenceAudioAndText() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .custom,
        text: "你好。",
        languageChoice: .automatic,
        speaker: "",
        instruct: "",
        refAudioPath: "",
        refText: ""
    )

    #expect(preview.missingRequirements == ["ref_audio", "ref_text"])
}

@Test func scriptStudioModelInputPreviewShowsMultiRoleInputsWithoutGlobalReference() {
    let text = """
    "小林": "25岁男性上班族，声音清亮但时常犹豫。"
    小林: 啊？我、我其实不太会喝酒。
    """

    let preview = ScriptStudioModelInputPreview.make(
        workflow: .multiRole,
        text: text,
        languageChoice: .automatic,
        speaker: "",
        instruct: "\"小林\": \"25岁男性上班族，声音清亮但时常犹豫。\"",
        refAudioPath: "",
        refText: ""
    )

    #expect(preview.visibleFields == [.language])
    #expect(preview.text == "啊？我、我其实不太会喝酒。")
    #expect(preview.instruct.isEmpty)
    #expect(!preview.isInstructEditable)
    #expect(preview.disabledInstructReason == "对话生成不使用角色控制指令；角色声线来自已绑定音色的 ref_audio/ref_text。")
    #expect(preview.refAudioPath == nil)
    #expect(preview.refText == nil)
    #expect(preview.missingRequirements.isEmpty)
}

@Test func scriptStudioModelInputPreviewDoesNotRequireMultiRoleDefinitions() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .multiRole,
        text: "小林: 其实我真的有发现，我是一个特别善于观察别人情绪的人。",
        languageChoice: .automatic,
        speaker: "",
        instruct: "",
        refAudioPath: "",
        refText: ""
    )

    #expect(preview.missingRequirements.isEmpty)
}

@Test func scriptStudioModelInputPreviewShowsVoiceDesignInputsOnly() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .voiceDesign,
        text: "今天我们讲一个技术问题。",
        languageChoice: .automatic,
        speaker: "Serena",
        instruct: "30岁女性纪录片旁白，低音沉稳。",
        refAudioPath: "/tmp/ref.wav",
        refText: "reference"
    )

    #expect(preview.visibleFields == [.language, .instruct])
    #expect(preview.requestLanguage == "Chinese")
    #expect(preview.instruct == "30岁女性纪录片旁白，低音沉稳。")
    #expect(preview.speaker == nil)
    #expect(preview.refAudioPath == nil)
    #expect(preview.refText == nil)
    #expect(preview.isInstructEditable)
}

@Test func scriptStudioModelInputPreviewCanPreserveRoleLabelsForVoiceDesignReuse() {
    let preview = ScriptStudioModelInputPreview.make(
        workflow: .voiceDesign,
        text: "小林: 啊？我、我其实不太会喝酒。",
        languageChoice: .automatic,
        speaker: "",
        instruct: "\"小林\": \"25岁男性上班族，声音清亮但时常犹豫。\"",
        refAudioPath: "",
        refText: "",
        preserveRoleLabels: true
    )

    #expect(preview.text == "小林: 啊？我、我其实不太会喝酒。")
    #expect(preview.instruct.contains("25岁男性"))
}

@Test func scriptStudioPromptSetAllowsManualPromptEditingBeforeGeneration() {
    let editedDelivery = ScriptStudioPromptSet(
        deliveryStylePrompt: "编译得到的控制指令",
        voiceIdentityDescription: "编译得到的声音身份",
        editedDeliveryStylePrompt: "用户直接编辑后的控制指令",
        editedVoiceIdentityDescription: nil
    )

    #expect(editedDelivery.activePrompt(for: .builtin) == "用户直接编辑后的控制指令")
    #expect(editedDelivery.activePrompt(for: .custom) == "用户直接编辑后的控制指令")
    #expect(editedDelivery.activePrompt(for: .voiceDesign) == "编译得到的声音身份")

    let editedDesign = ScriptStudioPromptSet(
        deliveryStylePrompt: "编译得到的控制指令",
        voiceIdentityDescription: "编译得到的声音身份",
        editedDeliveryStylePrompt: nil,
        editedVoiceIdentityDescription: "用户直接编辑后的声音身份"
    )

    #expect(editedDesign.activePrompt(for: .voiceDesign) == "用户直接编辑后的声音身份")
}

@Test func voiceControlPromptCompilerBuildsOfficialVoiceDesignRoleCard() {
    let profile = VoiceControlProfile(
        roleName: "林怀岳",
        language: "中文",
        dialect: "普通话",
        age: "年近七十",
        genderPresentation: "男性低沉声线",
        pitch: "低沉稳定",
        speed: "语速平稳",
        volume: "洪亮有力度",
        clarity: "吐字清晰",
        fluency: "表达流畅，一气呵成",
        accent: "标准普通话",
        emotion: "严肃坚定，带历史担当",
        tone: "权威、克制、富有感染力",
        persona: "资深战略科学家",
        acousticTexture: "浑厚，略带沙哑感",
        humanLikeness: "保留自然呼吸和关键停顿",
        background: "长期参与国家重大科技攻关",
        gradient: "开头沉稳，中段逐渐增强责任感，结尾收束得坚定",
        negativePrompt: "避免卡通化和过度表演",
        customPrompt: "关键名词放慢并加强清晰度"
    )

    let prompt = VoiceControlPromptCompiler.compile(profile: profile, workflow: .voiceDesign)

    #expect(prompt.contains("角色姓名：林怀岳"))
    #expect(prompt.contains("语言与口音：中文，标准普通话"))
    #expect(prompt.contains("声学属性：男性低沉声线，低沉稳定，语速平稳，洪亮有力度，吐字清晰"))
    #expect(prompt.contains("情绪与表演：严肃坚定，带历史担当，权威、克制、富有感染力"))
    #expect(!prompt.contains("="))
    #expect(prompt.contains("动态变化：开头沉稳，中段逐渐增强责任感，结尾收束得坚定"))
    #expect(prompt.contains("约束：避免卡通化和过度表演"))
    #expect(!prompt.contains("使用当前精品 speaker"))
}

@Test func voiceControlPromptCompilerDistinguishesCustomVoiceAndBaseCloneControl() {
    let profile = VoiceControlProfile(
        language: "中文",
        dialect: "四川话",
        speed: "慢速清晰",
        emotion: "温柔旁白",
        customPrompt: "不要改变参考音色的年龄感"
    )

    let builtinPrompt = VoiceControlPromptCompiler.compile(profile: profile, workflow: .builtin)
    let clonePrompt = VoiceControlPromptCompiler.compile(profile: profile, workflow: .custom)

    #expect(!builtinPrompt.contains("CustomVoice 指令控制"))
    #expect(!builtinPrompt.contains("不创造全新身份"))
    #expect(builtinPrompt.hasPrefix("语言与口音："))
    #expect(builtinPrompt.contains("语言与口音：中文，四川话"))
    #expect(clonePrompt.contains("Base Clone 弱提示"))
    #expect(!clonePrompt.contains("四川话"))
    #expect(!builtinPrompt.contains("="))
    #expect(!clonePrompt.contains("="))
    #expect(clonePrompt.contains("优先保持参考音频或 clone prompt 的音色"))
    #expect(clonePrompt.contains("补充指令：不要改变参考音色的年龄感"))

    let designPrompt = VoiceControlPromptCompiler.compile(profile: profile, workflow: .voiceDesign)
    #expect(!designPrompt.contains("方言=四川话"))
}

@Test func voiceControlPresetCatalogUsesOfficialControlCategories() {
    let base = VoiceControlProfile(language: "中文")
    let scientist = VoiceControlPreset.personaScientist.applying(to: base)
    let categories = Set(VoiceControlPreset.recommendedForVoiceDesign.map(\.category))

    #expect(VoiceControlPreset.recommendedForVoiceDesign.map(\.id).contains("official-acoustic-announcer"))
    #expect(VoiceControlPreset.recommendedForVoiceDesign.map(\.id).contains("official-gradient-outburst"))
    #expect(VoiceControlPreset.recommendedForVoiceDesign.map(\.id).contains("official-persona-scientist"))
    #expect(!VoiceControlPreset.recommendedForVoiceDesign.map(\.category).contains(.timbreReuse))
    #expect(categories.isSuperset(of: [
        .acousticAttributes,
        .ageIdentity,
        .emotionActing,
        .gradientControl,
        .personaBackground,
        .humanLikeness
    ]))
    #expect(!categories.contains(.multilingualDialect))
    #expect(scientist.roleName == "林怀岳")
    #expect(scientist.background.contains("国家重点科研项目"))
    #expect(VoiceControlPreset.recommendedForScriptStudio.count >= 6)
}

@Test func voiceControlAttributeCatalogProvidesEditableCandidateLists() {
    let definitions = VoiceControlAttributeCatalog.definitions
    let ids = Set(definitions.map(\.id))

    #expect(ids.isSuperset(of: [
        .roleName,
        .language,
        .dialect,
        .age,
        .genderPresentation,
        .pitch,
        .speed,
        .volume,
        .clarity,
        .fluency,
        .accent,
        .emotion,
        .tone,
        .persona,
        .acousticTexture,
        .humanLikeness,
        .background,
        .gradient,
        .negativePrompt,
        .customPrompt
    ]))
    #expect(definitions.allSatisfy { $0.candidates.count >= 20 })
    let languageCandidates = VoiceControlAttributeCatalog.definition(for: .language)?.candidates ?? []
    #expect(languageCandidates.contains("英文"))
    #expect(!languageCandidates.contains("English"))
    #expect(!languageCandidates.contains("Chinese"))
    #expect(VoiceControlAttributeCatalog.definition(for: .background)?.candidates.contains("太空舰桥的低频环境声") == true)
    #expect(VoiceControlAttributeCatalog.definition(for: .humanLikeness)?.candidates.contains("保留自然换气和轻微停顿") == true)
}

@Test func voiceControlAttributeCatalogHidesDialectOutsideCustomVoiceWorkflow() {
    #expect(VoiceControlAttributeCatalog.definitions(for: .builtin).map(\.id).contains(.dialect))
    #expect(!VoiceControlAttributeCatalog.definitions(for: .voiceDesign).map(\.id).contains(.dialect))
    #expect(!VoiceControlAttributeCatalog.definitions(for: .custom).map(\.id).contains(.dialect))
    #expect(!VoiceControlAttributeCatalog.definitions(for: .multiRole).map(\.id).contains(.dialect))
    #expect(VoiceControlAttributeCatalog.candidates(for: .dialect, workflow: .voiceDesign).isEmpty)
}

@Test func voiceControlAttributeCatalogUsesLanguageNeutralAccentCandidatesForVoiceDesign() {
    let candidates = VoiceControlAttributeCatalog.candidates(for: .accent, workflow: .voiceDesign)

    #expect(candidates.count >= 20)
    #expect(candidates.contains("新闻播报腔"))
    #expect(candidates.contains("自然口语发音"))
    #expect(!candidates.contains { $0.contains("英语") })
    #expect(!candidates.contains { $0.contains("日语") })
    #expect(!candidates.contains { $0.contains("俄语") })
    #expect(!candidates.contains { $0.contains("北京") || $0.contains("四川") })
}

@Test func voiceControlRandomizerSelectsOneCandidateForEveryAttribute() {
    var generator = SeededRandomNumberGenerator(seed: 42)
    let profile = VoiceControlRandomizer.randomizedProfile(workflow: .voiceDesign, using: &generator)

    for definition in VoiceControlAttributeCatalog.definitions(for: .voiceDesign) {
        let candidates = VoiceControlRandomizer.candidates(for: definition, workflow: .voiceDesign)
        #expect(candidates.contains(profile.value(for: definition.id)))
    }
    #expect(profile.dialect.isEmpty)
}

@Test func voiceInstructionLibraryInitializesOnceAndPreservesUserEdits() {
    var state = VoiceInstructionDraftState()
    let first = VoiceInstructionLibrary.templates(for: .customVoice)[0]
    let second = VoiceInstructionLibrary.templates(for: .customVoice)[1]

    let didInitialize = state.initializeIfNeeded(with: first)
    #expect(didInitialize)
    #expect(state.value == first.instruction)
    let didReinitialize = state.initializeIfNeeded(with: second)
    #expect(!didReinitialize)
    #expect(state.value == first.instruction)

    state.applyUserEdit("用户自定义：保持冷静旁白，但关键剧情前停顿。")
    let didOverwriteUserEdit = state.initializeIfNeeded(with: second)
    #expect(!didOverwriteUserEdit)
    #expect(state.value == "用户自定义：保持冷静旁白，但关键剧情前停顿。")
    #expect(state.wasEditedByUser)
}

@Test func voiceInstructionLibraryContainsWorkflowScopedOfficialStyleTemplates() {
    let custom = VoiceInstructionLibrary.templates(for: .customVoice)
    let voiceDesign = VoiceInstructionLibrary.templates(for: .voiceDesign)

    #expect(custom.count >= 20)
    #expect(voiceDesign.count >= 20)
    #expect(custom.allSatisfy { $0.workflow == .customVoice })
    #expect(voiceDesign.allSatisfy { $0.workflow == .voiceDesign })
    #expect(custom.contains { $0.instruction.contains("语速") && $0.instruction.contains("情绪") })
    #expect(voiceDesign.contains { $0.instruction.contains("背景") || $0.instruction.contains("场景") })
}

@Test func voiceControlPresetsExposeRegionalDialectOnlyForCustomVoiceWorkflow() {
    let builtinIDs = VoiceControlPreset.recommendedForScriptStudio(workflow: .builtin).map(\.id)
    #expect(builtinIDs.contains("beijing-dialogue"))
    #expect(builtinIDs.contains("sichuan-dialogue"))

    for workflow in [ScriptStudioWorkflow.custom, .voiceDesign, .multiRole] {
        let presets = VoiceControlPreset.recommendedForScriptStudio(workflow: workflow)
        #expect(!presets.map(\.id).contains("beijing-dialogue"))
        #expect(!presets.map(\.id).contains("sichuan-dialogue"))
        #expect(!presets.map(\.category).contains(.multilingualDialect))
    }
}

@Test func deepSeekVoiceEnhancementPromptRequiresConstraintPreservation() {
    let request = DeepSeekVoiceDescriptionRequest(
        description: "沉稳旁白，轻微反讽。",
        language: "Chinese",
        purpose: "短剧旁白",
        currentInstruction: "原始指令：不能删除。"
    )

    let messages = request.requestBody["messages"] as? [[String: String]] ?? []
    let combined = messages.map { $0["content"] ?? "" }.joined(separator: "\n")

    #expect(combined.contains("preserve every original constraint"))
    #expect(combined.contains("must not delete"))
    #expect(combined.contains("coverage_warnings"))
    #expect(combined.contains("enriched_instruction"))
}

@Test func deepSeekScriptRewritePromptForbidsDeletingSourceInformation() {
    let request = DeepSeekScriptRewriteRequest(
        sourceText: "小林推开门，发现桌上的信不见了。",
        contextSummary: "",
        stylePrompt: "科幻、克制"
    )

    let messages = request.requestBody["messages"] as? [[String: String]] ?? []
    let combined = messages.map { $0["content"] ?? "" }.joined(separator: "\n")

    #expect(combined.contains("不能删减原始文本的信息点"))
    #expect(combined.contains("保持原意"))
    #expect(combined.contains("不得摘要式压缩"))
    #expect(combined.contains("coverage_warnings"))
}

@Test func builtinVoiceDisplayNameAddsChineseNamesForLegacySpeakerRecords() {
    let legacy = VoiceProfile(name: "Serena", kind: .customVoice, language: "Chinese", speaker: "Serena")
    let alreadyLocalized = VoiceProfile(name: "苏瑶 Serena", kind: .customVoice, language: "Chinese", speaker: "Serena")

    #expect(BuiltinVoiceDisplayName.displayName(for: legacy) == "苏瑶 Serena")
    #expect(BuiltinVoiceDisplayName.chineseName(for: legacy) == "苏瑶")
    #expect(BuiltinVoiceDisplayName.displayName(for: alreadyLocalized) == "苏瑶 Serena")
}

@Test func builtinVoiceDisplayNameAddsNativeLanguageAndDialectLabels() {
    let dylan = VoiceProfile(name: "Dylan", kind: .customVoice, language: "Chinese", speaker: "Dylan")
    let eric = VoiceProfile(name: "Eric", kind: .customVoice, language: "Chinese", speaker: "Eric")
    let sohee = VoiceProfile(name: "Sohee", kind: .customVoice, language: "Korean", speaker: "Sohee")

    #expect(BuiltinVoiceDisplayName.nativeLanguageLabel(for: dylan) == "北京话")
    #expect(BuiltinVoiceDisplayName.nativeLanguageLabel(for: eric) == "四川话")
    #expect(BuiltinVoiceDisplayName.nativeLanguageLabel(for: sohee) == "韩语")
    #expect(BuiltinVoiceDisplayName.displayNameWithNativeLanguage(for: dylan) == "晓东 Dylan · 北京话")
    #expect(BuiltinVoiceDisplayName.displayNameWithNativeLanguage(for: eric) == "程川 Eric · 四川话")
    #expect(BuiltinVoiceDisplayName.displayNameWithNativeLanguage(for: sohee) == "素熙 Sohee · 韩语")
}

@Test func builtinVoiceDisplayNameProvidesDefaultLanguageChoiceForDialectSpeakers() {
    let dylan = VoiceProfile(name: "Dylan", kind: .customVoice, language: "Chinese", speaker: "Dylan")
    let eric = VoiceProfile(name: "Eric", kind: .customVoice, language: "Chinese", speaker: "Eric")
    let sohee = VoiceProfile(name: "Sohee", kind: .customVoice, language: "Korean", speaker: "Sohee")

    #expect(BuiltinVoiceDisplayName.defaultLanguageChoice(for: dylan).selectedOptions == [.beijingDialect])
    #expect(BuiltinVoiceDisplayName.defaultLanguageChoice(for: dylan).requestLanguage(for: "北京胡同里的风声很轻。") == "beijing_dialect")
    #expect(BuiltinVoiceDisplayName.defaultLanguageChoice(for: eric).selectedOptions == [.sichuanDialect])
    #expect(BuiltinVoiceDisplayName.defaultLanguageChoice(for: eric).requestLanguage(for: "你这个事情整得有点安逸。") == "sichuan_dialect")
    #expect(BuiltinVoiceDisplayName.defaultLanguageChoice(for: sohee).selectedOptions == [.korean])
}

@Test func chineseOrdinalFormatterBuildsItemAndPageLabels() {
    #expect(ChineseOrdinalFormatter.item(1) == "第一个")
    #expect(ChineseOrdinalFormatter.item(12) == "第十二个")
    #expect(ChineseOrdinalFormatter.page(4) == "第四页")
    #expect(ChineseOrdinalFormatter.page(30) == "第三十页")
}

@Test func generationProgressEstimatorReportsStableStageLabels() {
    let startup = GenerationProgressEstimator.estimatedTTSProgress(elapsedSeconds: 0.2)
    let sampling = GenerationProgressEstimator.estimatedTTSProgress(elapsedSeconds: 6.0)
    let writing = GenerationProgressEstimator.estimatedTTSProgress(elapsedSeconds: 20.0)

    #expect(startup.label == "启动 Python 后端")
    #expect(sampling.label == "生成音频采样")
    #expect(writing.label == "写入 WebM / 等待返回")
    #expect(startup.value > 0)
    #expect(writing.value <= 0.92)
}

@Test func generationResultsPaginationClampsJumpPageAndBuildsPageWindow() {
    let lastPage = GenerationResultsPagination(totalItems: 95, pageSize: 10, currentPage: 12)
    #expect(lastPage.totalPages == 10)
    #expect(lastPage.currentPage == 10)
    #expect(lastPage.itemRange == 90..<95)
    #expect(lastPage.visiblePageNumbers(maxVisible: 5) == [6, 7, 8, 9, 10])

    let middlePage = GenerationResultsPagination(totalItems: 95, pageSize: 10, currentPage: 5)
    #expect(middlePage.visiblePageNumbers(maxVisible: 5) == [3, 4, 5, 6, 7])

    let empty = GenerationResultsPagination(totalItems: 0, pageSize: 10, currentPage: -4)
    #expect(empty.totalPages == 1)
    #expect(empty.currentPage == 1)
    #expect(empty.itemRange == 0..<0)
}

@Test func playbackResumePointRestoresOnlySameAudioBeforeEnd() {
    let point = PlaybackResumePoint(audioID: "record-1", audioPath: "/tmp/a.wav", currentTime: 12.4, duration: 30)

    #expect(point.resumeTime(forAudioID: "record-1", audioPath: "/tmp/a.wav") == 12.4)
    #expect(point.resumeTime(forAudioID: "record-2", audioPath: "/tmp/a.wav") == nil)
    #expect(point.resumeTime(forAudioID: "record-1", audioPath: "/tmp/b.wav") == nil)
    #expect(point.progress == 12.4 / 30)
}

@Test func playbackResumePointDoesNotResumeAtBeginningOrFinishedTail() {
    let beginning = PlaybackResumePoint(audioID: "record", audioPath: "/tmp/a.wav", currentTime: 0.01, duration: 10)
    let finished = PlaybackResumePoint(audioID: "record", audioPath: "/tmp/a.wav", currentTime: 9.92, duration: 10)

    #expect(beginning.resumeTime(forAudioID: "record", audioPath: "/tmp/a.wav") == nil)
    #expect(finished.resumeTime(forAudioID: "record", audioPath: "/tmp/a.wav") == nil)
}

@Test func playbackQueueControlStateUsesPauseLabelsWhilePlaying() {
    let stopped = PlaybackQueueControlState(isPlaying: false)
    let playing = PlaybackQueueControlState(isPlaying: true)

    #expect(stopped.title == "播放全文")
    #expect(stopped.systemImage == "play.circle")
    #expect(stopped.shouldPauseOnTap == false)
    #expect(playing.title == "暂停全文")
    #expect(playing.systemImage == "pause.circle")
    #expect(playing.shouldPauseOnTap)
}

@Test func audioDurationFormatterShowsSecondsMinutesAndUnknownState() {
    #expect(AudioDurationFormatter.displayText(nil) == "未检测")
    #expect(AudioDurationFormatter.displayText(-2) == "未检测")
    #expect(AudioDurationFormatter.displayText(0.04) == "0.0 秒")
    #expect(AudioDurationFormatter.displayText(12.34) == "12.3 秒")
    #expect(AudioDurationFormatter.displayText(65.2) == "1 分 05 秒")
    #expect(AudioDurationFormatter.displayText(3723.8) == "62 分 04 秒")
    #expect(AudioDurationFormatter.labelText(65.2) == "时长：1 分 05 秒")
}

@Test func playbackQueueResumeStateResumesFromPausedItemAndKeepsFollowingItems() {
    let paths = ["/tmp/one.wav", "/tmp/two.wav", "/tmp/three.wav"]
    let state = PlaybackQueueResumeState(itemIndex: 1, itemPath: "/tmp/two.wav", currentTime: 4.2, duration: 20)
    let plan = state.resumePlan(for: paths)

    #expect(plan?.startIndex == 1)
    #expect(plan?.resumeTime == 4.2)
    #expect(plan?.remainingPaths == ["/tmp/two.wav", "/tmp/three.wav"])
}

@Test func playbackQueueResumeStateRejectsChangedQueueOrFinishedTail() {
    let paths = ["/tmp/one.wav", "/tmp/two.wav", "/tmp/three.wav"]
    let changed = PlaybackQueueResumeState(itemIndex: 1, itemPath: "/tmp/old-two.wav", currentTime: 4.2, duration: 20)
    let finished = PlaybackQueueResumeState(itemIndex: 1, itemPath: "/tmp/two.wav", currentTime: 19.95, duration: 20)

    #expect(changed.resumePlan(for: paths) == nil)
    #expect(finished.resumePlan(for: paths) == nil)
}

@Test func generationQueueSummarySeparatesSuccessFailureSkippedAndCancelled() {
    let completed = GenerationQueueSummary(total: 4, succeeded: 2, failed: 1, skipped: 1)
    let cancelled = GenerationQueueSummary(total: 5, succeeded: 2, failed: 0, skipped: 1, cancelled: true)

    #expect(completed.statusText == "全文生成队列完成：成功 2/4，失败 1，跳过 1")
    #expect(cancelled.statusText == "全文生成队列已取消：成功 2/5，失败 0，跳过 1")
}

@Test func generationQueueMergePlannerRequiresCompleteOrderedSegmentAudio() {
    let summary = GenerationQueueSummary(total: 3, succeeded: 3)
    let plan = GenerationQueueMergePlanner.plan(
        summary: summary,
        orderedSegmentIDs: ["seg-1", "seg-2", "seg-3"],
        audioPathsBySegmentID: [
            "seg-3": "/tmp/third.wav",
            "seg-1": "/tmp/first.wav",
            "seg-2": "/tmp/second.wav"
        ],
        outputName: "dialogue-full.wav"
    )

    #expect(plan?.paths == ["/tmp/first.wav", "/tmp/second.wav", "/tmp/third.wav"])
    #expect(plan?.outputName == "dialogue-full.wav")

    let partial = GenerationQueueMergePlanner.plan(
        summary: GenerationQueueSummary(total: 3, succeeded: 2, failed: 1),
        orderedSegmentIDs: ["seg-1", "seg-2", "seg-3"],
        audioPathsBySegmentID: [
            "seg-1": "/tmp/first.wav",
            "seg-2": "/tmp/second.wav"
        ],
        outputName: "partial.wav"
    )
    #expect(partial == nil)

    let missingPath = GenerationQueueMergePlanner.plan(
        summary: summary,
        orderedSegmentIDs: ["seg-1", "seg-2", "seg-3"],
        audioPathsBySegmentID: [
            "seg-1": "/tmp/first.wav",
            "seg-2": "/tmp/second.wav"
        ],
        outputName: "missing.wav"
    )
    #expect(missingPath == nil)
}

@Test func generationQueueMergePlannerCarriesInterSegmentGapSeconds() {
    let plan = GenerationQueueMergePlanner.plan(
        summary: GenerationQueueSummary(total: 2, succeeded: 2),
        orderedSegmentIDs: ["seg-1", "seg-2"],
        audioPathsBySegmentID: [
            "seg-1": "/tmp/first.wav",
            "seg-2": "/tmp/second.wav"
        ],
        outputName: "dialogue-full.wav",
        gapSeconds: 0.65
    )

    #expect(plan?.gapSeconds == 0.65)
}

@Test func voiceToolsAudioMergePlannerAcceptsMainstreamAudioInputs() {
    let plan = VoiceToolsAudioMergePlanner.plan(
        paths: ["/tmp/first.WAV", "/tmp/second.MP3", "/tmp/third.m4a", "/tmp/fourth.WEBM"],
        outputName: "my-mix.WEBM"
    )

    #expect(plan?.paths == ["/tmp/first.WAV", "/tmp/second.MP3", "/tmp/third.m4a", "/tmp/fourth.WEBM"])
    #expect(plan?.outputName == "my-mix.WEBM")

    #expect(VoiceToolsAudioMergePlanner.plan(paths: ["/tmp/only.WEBM"], outputName: "one") == nil)
    #expect(VoiceToolsAudioMergePlanner.plan(paths: ["/tmp/first.txt", "/tmp/second.WEBM"], outputName: "bad") == nil)
}

@Test func huggingFaceDownloadPlanMakesEndpointExplicit() {
    let official = HuggingFaceDownloadPlan(repository: "org/model", localPath: "/tmp/model")
    let mirror = HuggingFaceDownloadPlan(repository: "org/model", localPath: "/tmp/model", endpoint: " https://hf-mirror.com ")

    #expect(official.shellCommand == "hf download org/model --local-dir \"/tmp/model\"")
    #expect(official.processEnvironment.isEmpty)
    #expect(mirror.shellCommand == "HF_ENDPOINT=\"https://hf-mirror.com\" hf download org/model --local-dir \"/tmp/model\"")
    #expect(mirror.processEnvironment == ["HF_ENDPOINT": "https://hf-mirror.com"])
}

@Test func huggingFaceDownloadPlanSupportsDryRunAndFallback() {
    let mirror = HuggingFaceDownloadPlan(repository: "org/model", localPath: "/tmp/model", endpoint: HuggingFaceDownloadPlan.mirrorEndpoint)
    let official = mirror.fallbackToOfficial()

    #expect(mirror.dryRunArguments == ["download", "org/model", "--local-dir", "/tmp/model", "--dry-run", "--format", "json"])
    #expect(mirror.downloadArguments == ["download", "org/model", "--local-dir", "/tmp/model"])
    #expect(official.endpoint == HuggingFaceDownloadPlan.officialEndpoint)
    #expect(official.processEnvironment.isEmpty)
}

@Test func appPathsDefaultToVisibleDocumentsWorkspaceAndExposeLegacyRoot() {
    let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)

    #expect(AppPaths.defaultRoot(homeDirectory: home).path == "/Users/example/Documents/VoiceStudio/Workspace")
    #expect(AppPaths.legacyApplicationSupportRoot(homeDirectory: home).path == "/Users/example/Library/Application Support/MacQwenVoice")
    #expect(AppPaths.legacyDocumentsWorkspaceRoots(homeDirectory: home).map(\.path) == [
        "/Users/example/Documents/MacQwenVoice Workspace",
        "/Users/example/Documents/MacQwenVoice/Workspace"
    ])
    #expect(AppPaths(root: AppPaths.defaultRoot(homeDirectory: home)).database.path == "/Users/example/Documents/VoiceStudio/Workspace/database/MacQwenVoice.sqlite")
    #expect(AppPaths(root: AppPaths.defaultRoot(homeDirectory: home)).projects.path == "/Users/example/Documents/VoiceStudio/Workspace/projects")
    #expect(AppPaths(root: AppPaths.defaultRoot(homeDirectory: home)).deepSeekConfig.path == "/Users/example/Documents/VoiceStudio/Workspace/config/deepseek.json")
}

@Test func workspaceRootPreferencePersistsCustomRootAndCanResetToDefault() throws {
    let suiteName = "VoiceStudioWorkspaceRootPreferenceTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)
    let customRoot = URL(fileURLWithPath: "/Volumes/FastDisk/VoiceStudio Workspace", isDirectory: true)

    #expect(WorkspaceRootPreference.load(defaults: defaults, homeDirectory: home).path == "/Users/example/Documents/VoiceStudio/Workspace")
    #expect(WorkspaceRootPreference.isDefaultRoot(AppPaths.defaultRoot(homeDirectory: home), homeDirectory: home))

    WorkspaceRootPreference.save(customRoot, defaults: defaults)
    #expect(WorkspaceRootPreference.load(defaults: defaults, homeDirectory: home).path == "/Volumes/FastDisk/VoiceStudio Workspace")
    #expect(!WorkspaceRootPreference.isDefaultRoot(customRoot, homeDirectory: home))

    WorkspaceRootPreference.reset(defaults: defaults)
    #expect(WorkspaceRootPreference.load(defaults: defaults, homeDirectory: home).path == "/Users/example/Documents/VoiceStudio/Workspace")
}

@Test func workspaceStartupPolicyHidesManualBannerDuringAutomaticInitialization() {
    #expect(WorkspaceStartupPolicy.initialStatusMessage == "正在初始化 workspace")
    #expect(!WorkspaceStartupPolicy.shouldShowManualInitBanner(workspaceReady: true, isInitializing: false))
    #expect(!WorkspaceStartupPolicy.shouldShowManualInitBanner(workspaceReady: false, isInitializing: true))
    #expect(WorkspaceStartupPolicy.shouldShowManualInitBanner(workspaceReady: false, isInitializing: false))
}

@Test func workspaceMigrationCopiesLegacyContentAndRewritesModelPaths() throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: base) }
    let legacy = base.appendingPathComponent("Legacy", isDirectory: true)
    let target = base.appendingPathComponent("Workspace", isDirectory: true)
    let model = legacy.appendingPathComponent("models/mlx-community__Qwen3-TTS-12Hz-0.6B-Base-8bit", isDirectory: true)
    try FileManager.default.createDirectory(at: model, withIntermediateDirectories: true)
    try "config".write(to: model.appendingPathComponent("config.json"), atomically: true, encoding: .utf8)
    try "weights".write(to: model.appendingPathComponent("model.safetensors"), atomically: true, encoding: .utf8)

    let legacyDB = try AppDatabase(path: legacy.appendingPathComponent("database/MacQwenVoice.sqlite").path)
    try legacyDB.saveModelState(ModelState(id: "qwen3-tts-12hz-0.6b-base", localPath: model.path, status: .ready, bytes: 7))
    let legacyReference = legacy.appendingPathComponent("references/ref.wav").path
    let legacyPrompt = legacy.appendingPathComponent("clone_prompts/ref.json").path
    let legacyOutput = legacy.appendingPathComponent("outputs/result.wav").path
    _ = try legacyDB.saveVoice(
        VoiceProfile(
            id: "clone-voice",
            name: "旧克隆音色",
            kind: .clonedVoice,
            language: "Chinese",
            instruct: "自然",
            referenceAudioPath: legacyReference,
            referenceText: "参考文本",
            consentID: "consent-1",
            createdAt: Date(timeIntervalSince1970: 1)
        )
    )
    _ = try legacyDB.saveConsent(ConsentRecord(id: "consent-1", audioSource: legacyReference, purpose: "授权", createdAt: Date(timeIntervalSince1970: 2)))
    _ = try legacyDB.saveVoiceAsset(
        VoiceAsset(
            id: "clone-voice",
            type: .clonedVoice,
            speaker: "旧克隆音色",
            language: "Chinese",
            instruct: "自然",
            refAudioPath: legacyReference,
            refText: "参考文本",
            clonePromptPath: legacyPrompt,
            consentID: "consent-1",
            createdAt: Date(timeIntervalSince1970: 3)
        )
    )
    _ = try legacyDB.saveReferenceRecording(
        ReferenceRecording(
            id: "recording-1",
            path: legacyReference,
            duration: 3,
            transcript: "参考文本",
            consentID: "consent-1",
            createdAt: Date(timeIntervalSince1970: 4)
        )
    )
    try legacyDB.saveGeneration(
        GenerationRecord(
            id: "generation-1",
            mode: "voice_clone",
            modelID: "qwen3-tts-12hz-0.6b-base",
            voiceAssetID: "clone-voice",
            text: "生成文本",
            instruct: "自然",
            audioPath: legacyOutput,
            runtime: "mlx-audio",
            status: .ready,
            error: nil,
            createdAt: Date(timeIntervalSince1970: 5)
        )
    )

    let result = try WorkspaceMigrator.migrateIfNeeded(from: legacy, to: target, catalog: .default)

    #expect(result.didMigrate)
    #expect(FileManager.default.fileExists(atPath: target.appendingPathComponent("models/mlx-community__Qwen3-TTS-12Hz-0.6B-Base-8bit/config.json").path))
    let migratedDB = try AppDatabase(path: target.appendingPathComponent("database/MacQwenVoice.sqlite").path)
    let migratedState = try #require(migratedDB.listModelStates().first { $0.id == "qwen3-tts-12hz-0.6b-base" })
    #expect(migratedState.localPath == target.appendingPathComponent("models/mlx-community__Qwen3-TTS-12Hz-0.6B-Base-8bit").path)
    #expect(try migratedDB.listVoices().first { $0.id == "clone-voice" }?.referenceAudioPath == target.appendingPathComponent("references/ref.wav").path)
    #expect(try migratedDB.listConsents().first { $0.id == "consent-1" }?.audioSource == target.appendingPathComponent("references/ref.wav").path)
    #expect(try migratedDB.listVoiceAssets().first { $0.id == "clone-voice" }?.clonePromptPath == target.appendingPathComponent("clone_prompts/ref.json").path)
    #expect(try migratedDB.listReferenceRecordings().first { $0.id == "recording-1" }?.path == target.appendingPathComponent("references/ref.wav").path)
    #expect(try migratedDB.listGenerations().first { $0.id == "generation-1" }?.audioPath == target.appendingPathComponent("outputs/result.wav").path)
}

@Test func workspaceRelocationMovesOldDocumentsWorkspaceAndRewritesPaths() throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: base) }
    let legacy = base.appendingPathComponent("Documents/MacQwenVoice Workspace", isDirectory: true)
    let target = base.appendingPathComponent("Documents/VoiceStudio/Workspace", isDirectory: true)
    let model = legacy.appendingPathComponent("models/mlx-community__Qwen3-TTS-12Hz-0.6B-Base-8bit", isDirectory: true)
    try FileManager.default.createDirectory(at: model, withIntermediateDirectories: true)
    try "weights".write(to: model.appendingPathComponent("model.safetensors"), atomically: true, encoding: .utf8)

    let legacyDB = try AppDatabase(path: legacy.appendingPathComponent("database/MacQwenVoice.sqlite").path)
    try legacyDB.saveModelState(ModelState(id: "qwen3-tts-12hz-0.6b-base", localPath: model.path, status: .ready, bytes: 7))

    let result = try WorkspaceMigrator.relocateWorkspaceIfNeeded(from: [legacy], to: target, catalog: .default)

    #expect(result.didMigrate)
    #expect(!FileManager.default.fileExists(atPath: legacy.path))
    #expect(FileManager.default.fileExists(atPath: target.appendingPathComponent("models/mlx-community__Qwen3-TTS-12Hz-0.6B-Base-8bit/model.safetensors").path))
    let migratedDB = try AppDatabase(path: target.appendingPathComponent("database/MacQwenVoice.sqlite").path)
    let migratedState = try #require(migratedDB.listModelStates().first { $0.id == "qwen3-tts-12hz-0.6b-base" })
    #expect(migratedState.localPath == target.appendingPathComponent("models/mlx-community__Qwen3-TTS-12Hz-0.6B-Base-8bit").path)
}

@Test func workspaceMigrationDoesNotOverwriteExistingCustomModelPathsWhenNothingMigrates() throws {
    let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: base) }
    let legacy = base.appendingPathComponent("Legacy", isDirectory: true)
    let target = base.appendingPathComponent("Workspace", isDirectory: true)
    let targetPaths = AppPaths(root: target)
    try targetPaths.ensureDirectories()
    try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
    let bf16Path = targetPaths.models.appendingPathComponent("mlx-community__Qwen3-TTS-12Hz-1.7B-VoiceDesign-bf16", isDirectory: true).path

    let targetDB = try AppDatabase(path: targetPaths.database.path)
    try targetDB.saveModelState(
        ModelState(
            id: "qwen3-tts-12hz-1.7b-voicedesign",
            localPath: bf16Path,
            status: .ready,
            bytes: 4515695681
        )
    )

    let result = try WorkspaceMigrator.migrateIfNeeded(from: legacy, to: target, catalog: .default)

    #expect(!result.didMigrate)
    let state = try #require(targetDB.listModelStates().first { $0.id == "qwen3-tts-12hz-1.7b-voicedesign" })
    #expect(state.localPath == bf16Path)
}

@Test func voiceLibraryGroupingSeparatesBuiltinAndCustomVoices() {
    let builtIn = VoiceProfile(name: "Vivian", kind: .customVoice, language: "Chinese")
    let clone = VoiceProfile(name: "我的克隆音色", kind: .clonedVoice, language: "Chinese")
    let design = VoiceProfile(name: "角色音色", kind: .voiceDesign, language: "Chinese")
    let grouping = VoiceLibraryGrouping(voices: [clone, builtIn, design])

    #expect(grouping.builtin.map(\.name) == ["Vivian"])
    #expect(grouping.clonedCustom.map(\.name) == ["我的克隆音色"])
    #expect(grouping.designedCustom.map(\.name) == ["角色音色"])
    #expect(grouping.custom.map(\.name) == ["我的克隆音色", "角色音色"])
}

@Test func roleVoiceBindingMatcherMatchesDesignedVoicesByNameSpeakerAndGeneratedPrefix() {
    let namedDesign = VoiceProfile(name: "小林", kind: .voiceDesign, language: "Chinese")
    let speakerDesign = VoiceProfile(name: "角色资产", kind: .voiceDesign, language: "Chinese", speaker: "御姐")
    let generatedDesign = VoiceProfile(name: "角色 · 旁白", kind: .voiceDesign, language: "Chinese")

    #expect(RoleVoiceBindingMatcher.matches(roleName: "小林", voice: namedDesign))
    #expect(RoleVoiceBindingMatcher.matches(roleName: "御姐", voice: speakerDesign))
    #expect(RoleVoiceBindingMatcher.matches(roleName: "旁白", voice: generatedDesign))
    #expect(!RoleVoiceBindingMatcher.matches(roleName: "小林", voice: speakerDesign))
}

@Test func voiceSelectionSummaryBuildsCompactMultiSelectLabels() {
    #expect(VoiceSelectionSummary.countLabel(selectedCount: 0, totalCount: 12) == "未选择 / 共 12")
    #expect(VoiceSelectionSummary.countLabel(selectedCount: 3, totalCount: 12) == "已选 3 / 共 12")
    #expect(VoiceSelectionSummary.namesSummary([]) == "展开后勾选要用于对话的创造音色")
    #expect(VoiceSelectionSummary.namesSummary(["旁白", "小林", "御姐", "老板"]) == "旁白、小林、御姐 等 4 个")
}

@Test func runtimeInstallerProgressParsesStepLines() {
    let progress = RuntimeInstallerProgress.parse(line: "VOICE_STUDIO_STEP 3/8 Installing Python packages")

    #expect(progress?.currentStep == 3)
    #expect(progress?.totalSteps == 8)
    #expect(progress?.message == "Installing Python packages")
    #expect(progress?.fraction == 0.375)
}

@Test func runtimeInstallerProgressIgnoresRegularLogLines() {
    #expect(RuntimeInstallerProgress.parse(line: "Installing mlx-audio...") == nil)
    #expect(RuntimeInstallerProgress.parse(line: "VOICE_STUDIO_STEP bad Installing") == nil)
}

@Test func voiceSourceSelectionMakesBuiltinAndCustomVoiceExclusive() {
    let builtIn = VoiceProfile(id: "builtin", name: "Vivian", kind: .customVoice, language: "Chinese")
    let clone = VoiceProfile(id: "clone", name: "我的克隆音色", kind: .clonedVoice, language: "Chinese")
    let design = VoiceProfile(id: "design", name: "创造角色音色", kind: .voiceDesign, language: "Chinese")

    #expect(VoiceSourceSelection.source(for: builtIn) == .builtin)
    #expect(VoiceSourceSelection.source(for: clone) == .custom)
    #expect(VoiceSourceSelection.source(for: design) == .custom)
    #expect(VoiceSourceSelection.builtinSelectedID(selectedVoiceID: "builtin", voices: [builtIn, clone, design]) == "builtin")
    #expect(VoiceSourceSelection.customSelectedID(selectedVoiceID: "builtin", voices: [builtIn, clone, design]) == nil)
    #expect(VoiceSourceSelection.builtinSelectedID(selectedVoiceID: "clone", voices: [builtIn, clone, design]) == nil)
    #expect(VoiceSourceSelection.customSelectedID(selectedVoiceID: "clone", voices: [builtIn, clone, design]) == "clone")
    #expect(VoiceSourceSelection.customSelectedID(selectedVoiceID: "design", voices: [builtIn, clone, design]) == "design")
}

@Test func customVoiceNameAvailabilityRejectsDuplicateCloneAndDesignNames() {
    let builtIn = VoiceProfile(id: "builtin", name: "我的音色", kind: .customVoice, language: "Chinese")
    let clone = VoiceProfile(id: "clone", name: " 我的音色 ", kind: .clonedVoice, language: "Chinese")
    let design = VoiceProfile(id: "design", name: "Role Voice", kind: .voiceDesign, language: "English")
    let voices = [builtIn, clone, design]

    #expect(!CustomVoiceNameAvailability.isAvailable("我的音色", voices: voices))
    #expect(!CustomVoiceNameAvailability.isAvailable("role voice", voices: voices))
    #expect(CustomVoiceNameAvailability.isAvailable("新的音色", voices: voices))
    #expect(CustomVoiceNameAvailability.isAvailable("我的音色", voices: voices, excludingVoiceID: "clone"))
    #expect(CustomVoiceNameAvailability.isAvailable("我的音色", voices: [builtIn]))
}

@Test func voiceDesignSaveNameValidationReportsEmptyDuplicateAndAvailableNames() {
    let voices = [
        VoiceProfile(id: "builtin", name: "旁白", kind: .customVoice, language: "Chinese"),
        VoiceProfile(id: "design", name: " 科普旁白 ", kind: .voiceDesign, language: "Chinese")
    ]

    #expect(VoiceDesignSaveNameValidation.state(for: "  ", voices: voices) == .empty)
    #expect(VoiceDesignSaveNameValidation.state(for: "科普旁白", voices: voices) == .duplicate)
    #expect(VoiceDesignSaveNameValidation.state(for: "新角色音色", voices: voices) == .available)
    #expect(VoiceDesignSaveNameValidation.state(for: "旁白", voices: voices) == .available)
    #expect(VoiceDesignSaveNameValidation.state(for: "新角色音色", voices: voices).message == nil)
    #expect(VoiceDesignSaveNameValidation.state(for: "科普旁白", voices: voices).message == "音色名称已存在，请换一个名称再保存")
}

@Test func voiceStudioDefaultsProvideReadableCloneTranscript() {
    #expect(!VoiceStudioDefaults.cloneReferenceTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    #expect(VoiceStudioDefaults.cloneReferenceTranscript.contains("夜色"))
    #expect(VoiceStudioDefaults.defaultProjectTitle == "新旁白项目")
}

@Test func voiceStudioDefaultsProvideModernCloneTranscriptExamples() {
    #expect(VoiceStudioDefaults.cloneReferenceTranscriptExamples.count == 2)
    #expect(VoiceStudioDefaults.cloneReferenceTranscriptExamples[0].language == "中文")
    #expect(VoiceStudioDefaults.cloneReferenceTranscriptExamples[1].language == "English")
    #expect(VoiceStudioDefaults.cloneReferenceTranscriptExamples[0].examples.first == VoiceStudioDefaults.cloneReferenceTranscript)
    #expect(VoiceStudioDefaults.cloneReferenceTranscriptExamples[0].examples.allSatisfy { !$0.contains("明月") && !$0.contains("古诗") })
    #expect(VoiceStudioDefaults.cloneReferenceTranscriptExamples[1].examples.allSatisfy { $0.contains(" ") && !$0.contains("Shall I compare") })
    #expect(VoiceStudioDefaults.allCloneReferenceTranscriptExamples.count == 12)
    #expect(VoiceStudioDefaults.allCloneReferenceTranscriptExamples.first == VoiceStudioDefaults.cloneReferenceTranscript)
    #expect(Set(VoiceStudioDefaults.allCloneReferenceTranscriptExamples).count == VoiceStudioDefaults.allCloneReferenceTranscriptExamples.count)
}

@Test func privacyUsageDescriptionsReportMissingMicrophoneAndSpeechKeys() {
    let complete: [String: Any] = [
        PrivacyUsageDescriptions.microphoneKey: "录音",
        PrivacyUsageDescriptions.speechRecognitionKey: "语音识别"
    ]
    let missingSpeech: [String: Any] = [
        PrivacyUsageDescriptions.microphoneKey: "录音"
    ]

    #expect(PrivacyUsageDescriptions.missingKeys(for: [.microphone, .speechRecognition], in: complete).isEmpty)
    #expect(PrivacyUsageDescriptions.missingKeys(for: [.microphone, .speechRecognition], in: missingSpeech) == [PrivacyUsageDescriptions.speechRecognitionKey])
    #expect(PrivacyUsageDescriptions.missingKeys(for: [.microphone], in: nil) == [PrivacyUsageDescriptions.microphoneKey])
}

@Test func segmentResultStateUsesSinglePrimaryGenerationAction() {
    let idle = SegmentResultState(audioPath: nil, error: nil)
    let ready = SegmentResultState(audioPath: "/tmp/a.wav", error: nil)
    let failed = SegmentResultState(audioPath: nil, error: "failed")

    #expect(idle.primaryActionTitle == "生成")
    #expect(ready.primaryActionTitle == "重新生成")
    #expect(failed.primaryActionTitle == "重新生成")
    #expect(ready.canPlay)
    #expect(!failed.canPlay)
}

@Test func speechTokenizerStoreSharesIdenticalTokenizerCopies() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let models = root.appendingPathComponent("models", isDirectory: true)
    let modelA = models.appendingPathComponent("model-a/speech_tokenizer", isDirectory: true)
    let modelB = models.appendingPathComponent("model-b/speech_tokenizer", isDirectory: true)
    try FileManager.default.createDirectory(at: modelA, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: modelB, withIntermediateDirectories: true)
    try Data("same tokenizer".utf8).write(to: modelA.appendingPathComponent("model.safetensors"))
    try Data("same tokenizer".utf8).write(to: modelB.appendingPathComponent("model.safetensors"))

    let result = try SpeechTokenizerStore.normalize(in: models)

    #expect(result.normalizedModels == 2)
    #expect(result.sharedCopies == 1)
    #expect(FileManager.default.fileExists(atPath: models.appendingPathComponent("shared/speech_tokenizer").path))
    #expect(FileManager.default.fileExists(atPath: modelA.path))
    #expect(FileManager.default.fileExists(atPath: modelB.path))
}

@Test func speechTokenizerStoreRepairsBrokenSharedTokenizerSymlinkAfterWorkspaceMove() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let models = root.appendingPathComponent("models", isDirectory: true)
    let sharedTokenizer = models.appendingPathComponent("shared/speech_tokenizer/hash-a", isDirectory: true)
    let modelTokenizer = models.appendingPathComponent("model-a/speech_tokenizer")
    let staleTokenizer = root.appendingPathComponent("old-workspace/models/shared/speech_tokenizer/hash-a")
    try FileManager.default.createDirectory(at: sharedTokenizer, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: modelTokenizer.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("same tokenizer".utf8).write(to: sharedTokenizer.appendingPathComponent("model.safetensors"))
    try FileManager.default.createSymbolicLink(at: modelTokenizer, withDestinationURL: staleTokenizer)

    let result = try SpeechTokenizerStore.normalize(in: models)

    #expect(result.normalizedModels == 1)
    #expect(result.sharedCopies == 0)
    #expect(FileManager.default.fileExists(atPath: modelTokenizer.appendingPathComponent("model.safetensors").path))
    #expect(try FileManager.default.destinationOfSymbolicLink(atPath: modelTokenizer.path) == sharedTokenizer.path)
}

@Test func speechTokenizerStoreIgnoresIncompleteTokenizerDirectories() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let models = root.appendingPathComponent("models", isDirectory: true)
    let incomplete = models.appendingPathComponent("incomplete-model/speech_tokenizer", isDirectory: true)
    try FileManager.default.createDirectory(at: incomplete, withIntermediateDirectories: true)

    let result = try SpeechTokenizerStore.normalize(in: models)

    #expect(result == .empty)
    #expect(FileManager.default.fileExists(atPath: incomplete.path))
    #expect(!FileManager.default.fileExists(atPath: models.appendingPathComponent("shared/speech_tokenizer").path))
}

@Test func huggingFaceEndpointPreferencePersistsOfficialMirrorAndCustomValues() throws {
    let suiteName = "MacQwenVoiceTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    #expect(HuggingFaceEndpointPreference.load(defaults: defaults, environment: [:]) == HuggingFaceDownloadPlan.mirrorEndpoint)
    #expect(HuggingFaceEndpointPreference.load(defaults: defaults, environment: ["HF_ENDPOINT": "https://example-mirror.local"]) == "https://example-mirror.local")

    HuggingFaceEndpointPreference.save("", defaults: defaults)
    #expect(HuggingFaceEndpointPreference.load(defaults: defaults, environment: ["HF_ENDPOINT": "https://example-mirror.local"]) == "")

    HuggingFaceEndpointPreference.save(" https://hf-mirror.com ", defaults: defaults)
    #expect(HuggingFaceEndpointPreference.load(defaults: defaults, environment: [:]) == "https://hf-mirror.com")
}

@Test func qwenModelDirectoryValidatorRejectsEmptyOrPartialDirectories() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let empty = root.appendingPathComponent("empty", isDirectory: true)
    let partial = root.appendingPathComponent("partial", isDirectory: true)
    let ready = root.appendingPathComponent("ready", isDirectory: true)
    try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: partial, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: ready, withIntermediateDirectories: true)
    try Data("{}".utf8).write(to: partial.appendingPathComponent("config.json"))
    try Data("{}".utf8).write(to: ready.appendingPathComponent("config.json"))
    try Data("weights".utf8).write(to: ready.appendingPathComponent("model.safetensors"))

    #expect(!QwenModelDirectoryValidator.isReady(atPath: root.appendingPathComponent("missing").path))
    #expect(!QwenModelDirectoryValidator.isReady(atPath: empty.path))
    #expect(!QwenModelDirectoryValidator.isReady(atPath: partial.path))
    #expect(QwenModelDirectoryValidator.isReady(atPath: ready.path))
}

@Test func cloneVoiceWorkflowStateRequiresAudioTranscriptConsentAndName() {
    let incomplete = CloneVoiceWorkflowState(
        name: "",
        referenceAudioPath: "",
        referenceText: "",
        purpose: "",
        duration: nil
    )
    let ready = CloneVoiceWorkflowState(
        name: "我的旁白音色",
        referenceAudioPath: "/tmp/ref.wav",
        referenceText: "这是一段参考音频的文字稿。",
        purpose: "本人声音，用于本地旁白创作",
        duration: 3.4
    )

    #expect(!incomplete.canSave)
    #expect(incomplete.missingRequirements == ["音色名称", "参考音频", "参考逐字稿", "授权用途"])
    #expect(ready.canSave)
    #expect(ready.missingRequirements.isEmpty)
    #expect(ready.durationText == "3.4 秒")
}

@Test func referenceRecordingPoliciesPreferNativeRateAndStableFiles() {
    #expect(ReferenceRecordingFormatPolicy.safeRecorderSampleRate == 48_000)
    #expect(ReferenceRecordingFormatPolicy.sanitizedSampleRate(48_000) == 48_000)
    #expect(ReferenceRecordingFormatPolicy.sanitizedSampleRate(44_100) == 44_100)
    #expect(ReferenceRecordingFormatPolicy.sanitizedSampleRate(0) == 48_000)
    #expect(ReferenceRecordingFormatPolicy.sanitizedSampleRate(192_000) == 48_000)

    let stability = RecordingFileStabilityPolicy(minimumBytes: 4_096, stableSampleCount: 2)
    #expect(!stability.isReady(recentSizes: [4_096]))
    #expect(!stability.isReady(recentSizes: [4_096, 8_192]))
    #expect(stability.isReady(recentSizes: [8_192, 8_192]))
    #expect(stability.isReady(recentSizes: [4_096, 8_192, 8_192]))
    #expect(!stability.isReady(recentSizes: [2_048, 2_048, 2_048]))
}

@Test func deepSeekConfigurationRequiresExplicitAPIKey() {
    #expect(!DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: nil, environment: [:]))
    #expect(!DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: "  ", environment: [:]))
    #expect(DeepSeekVoiceDescriptionRequest.isConfigured(apiKey: nil, environment: ["DEEPSEEK_API_KEY": "sk-test"]))
    #expect(DeepSeekVoiceDescriptionRequest.savedKeyPlaceholder == "********")
    #expect(DeepSeekVoiceDescriptionRequest.isSavedKeyPlaceholder(" ******** "))
    #expect(!DeepSeekVoiceDescriptionRequest.isSavedKeyPlaceholder("sk-test"))

    let payload = DeepSeekVoiceDescriptionRequest(
        description: "温暖、可信赖",
        language: "Chinese",
        purpose: "有声书旁白",
        controlType: "VoiceDesign 角色音色卡",
        synthesisText: "今天我们讲一个复杂但有意思的技术问题。",
        currentInstruction: "声学属性：语速平稳，音色温暖。"
    ).requestBody

    #expect(payload["model"] as? String == "deepseek-chat")
    let messages = payload["messages"] as? [[String: String]]
    #expect(messages?.first?["content"]?.contains("Qwen3-TTS") == true)
    #expect(messages?.first?["content"]?.contains("strict JSON") == true)
    #expect(messages?.last?["content"]?.contains("VoiceDesign 角色音色卡") == true)
    #expect(messages?.last?["content"]?.contains("声学属性") == true)
    #expect(messages?.last?["content"]?.contains("compiled_instruction") == true)
}

@Test func deepSeekVoiceDescriptionResponsePrefersCompiledInstructionFromJSON() {
    let response = """
    {
      "role_name": "科普旁白",
      "compiled_instruction": "角色姓名：科普旁白\\n声学属性：温暖、清晰。\\n情绪与表演：可信赖。",
      "preview_text": "今天我们讲一个技术问题。"
    }
    """

    #expect(
        DeepSeekVoiceDescriptionResponse.preferredInstruction(from: response)
            == "角色姓名：科普旁白\n声学属性：温暖、清晰。\n情绪与表演：可信赖。"
    )
    #expect(DeepSeekVoiceDescriptionResponse.preferredInstruction(from: "直接描述") == "直接描述")
}

@Test func deepSeekScriptRewriteRequestRequiresJSONShortDramaRules() {
    let payload = DeepSeekScriptRewriteRequest(
        sourceText: "雨停了。云天明望着落日，说这个世界像一场梦。",
        contextSummary: "蓝星傍晚，云天明和艾AA独处。",
        stylePrompt: "科幻、克制、沉浸式"
    ).requestBody

    #expect(payload["model"] as? String == "deepseek-chat")
    let responseFormat = payload["response_format"] as? [String: String]
    #expect(responseFormat?["type"] == "json_object")

    let messages = payload["messages"] as? [[String: String]]
    let systemPrompt = messages?.first?["content"] ?? ""
    let userPrompt = messages?.last?["content"] ?? ""
    #expect(systemPrompt.contains("script_text"))
    #expect(systemPrompt.contains("连续旁白必须合并"))
    #expect(systemPrompt.contains("删除音效"))
    #expect(systemPrompt.contains("角色名: 内容"))
    #expect(systemPrompt.contains("不要输出 Markdown"))
    #expect(userPrompt.contains("蓝星傍晚"))
    #expect(userPrompt.contains("雨停了"))
}

@Test func deepSeekScriptRewriteResponseExtractsRolesScriptAndWarnings() throws {
    let content = """
    {
      "roles": [
        {"name": "旁白", "voice_hint": "沉稳、有画面感"},
        {"name": "云天明", "voice_hint": "压抑、平静中带创伤感"}
      ],
      "script_text": "旁白: 雨停了，蓝草在晚风中摇摆。\\n云天明: 这个世界，像不像一场梦？",
      "warnings": ["原文过长时只改写当前片段"]
    }
    """

    let rewritten = try DeepSeekScriptRewriteResponse.parse(content: content)

    #expect(rewritten.roles.map(\.name) == ["旁白", "云天明"])
    #expect(rewritten.roles[0].voiceHint == "沉稳、有画面感")
    #expect(rewritten.scriptText == "旁白: 雨停了，蓝草在晚风中摇摆。\n云天明: 这个世界，像不像一场梦？")
    #expect(rewritten.warnings == ["原文过长时只改写当前片段"])
    #expect(SpeakerTaggedTextNormalizer.roleNames(from: rewritten.scriptText) == ["旁白", "云天明"])
}

@Test func deepSeekScriptRewriteResponseRejectsEmptyOrUnroutedScript() {
    #expect(throws: Error.self) {
        try DeepSeekScriptRewriteResponse.parse(content: """
        {"roles": [{"name": "旁白", "voice_hint": "沉稳"}], "script_text": "   ", "warnings": []}
        """)
    }

    #expect(throws: Error.self) {
        try DeepSeekScriptRewriteResponse.parse(content: """
        {"roles": [], "script_text": "这是一段没有角色标签的文本。", "warnings": []}
        """)
    }
}

@Test func deepSeekAPIKeyConfigStorePersistsReadableJSONAndDeletesCleanly() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let paths = AppPaths(root: root)
    let store = DeepSeekAPIKeyConfigStore(fileURL: paths.deepSeekConfig)

    #expect(try store.read() == nil)

    try store.save(" sk-live-test ")
    #expect(try store.read() == "sk-live-test")

    let data = try Data(contentsOf: paths.deepSeekConfig)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(object["provider"] as? String == "deepseek")
    #expect(object["api_key"] as? String == "sk-live-test")

    try store.delete()
    #expect(try store.read() == nil)
}

@Test func workspaceSectionsExposeDedicatedSettingsPageForDeepSeekConfiguration() {
    #expect(WorkspaceSection.allCases.contains(.settings))
    #expect(WorkspaceSection.settings.title == "设置")
    #expect(WorkspaceSection.settings.systemImage == "gearshape")
}

@Test func workspaceSectionsUseShortModelTitle() {
    #expect(WorkspaceSection.models.title == "模型")
}

@Test func workspaceSectionsUseDialogueRewriteTitle() {
    #expect(WorkspaceSection.scriptRewrite.title == "对话改写")
}

@Test func sqliteStorePersistsProjectVoiceModelAndConsent() throws {
    let dbURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("sqlite")
    defer { try? FileManager.default.removeItem(at: dbURL) }

    let store = try AppDatabase(path: dbURL.path)
    let voiceID = try store.saveVoice(
        VoiceProfile(
            id: "voice-1",
            name: "旁白女声",
            kind: .customVoice,
            language: "Chinese",
            speaker: "Serena",
            instruct: "温柔、清晰",
            referenceAudioPath: nil,
            referenceText: nil,
            consentID: nil,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
    )
    try store.saveModelState(ModelState(id: "qwen3-tts-12hz-0.6b-base", localPath: "/models/base", status: .ready, bytes: 42))
    let consentID = try store.saveConsent(ConsentRecord(id: "consent-1", audioSource: "/tmp/ref.wav", purpose: "个人授权旁白", createdAt: Date(timeIntervalSince1970: 1_800_000_001)))
    let projectID = try store.saveProject(title: "测试项目", rawText: "第一段。\n\n第二段。", defaultVoiceID: voiceID)

    #expect(consentID == "consent-1")
    #expect(try store.listVoices().map(\.id) == ["voice-1"])
    #expect(try store.listModelStates().first?.status == .ready)
    #expect(try store.listProjects().first?.id == projectID)
}

@Test func sqliteStorePersistsVoiceAssetsReferenceRecordingsAndGenerations() throws {
    let dbURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("sqlite")
    defer { try? FileManager.default.removeItem(at: dbURL) }

    let store = try AppDatabase(path: dbURL.path)
    let assetID = try store.saveVoiceAsset(
        VoiceAsset(
            id: "asset-1",
            type: .clonedVoice,
            speaker: "我的声音",
            language: "Chinese",
            instruct: "自然、口语化",
            refAudioPath: "/refs/me.wav",
            refText: "参考文字",
            clonePromptPath: "/prompts/me.json",
            consentID: "consent-1",
            createdAt: Date(timeIntervalSince1970: 1_800_000_010)
        )
    )
    let recordingID = try store.saveReferenceRecording(
        ReferenceRecording(
            id: "recording-1",
            path: "/refs/recording.wav",
            duration: 3.2,
            transcript: "录音文字稿",
            consentID: "consent-1",
            createdAt: Date(timeIntervalSince1970: 1_800_000_011)
        )
    )
    try store.saveGeneration(
        GenerationRecord(
            id: "generation-1",
            mode: "voice_clone",
            modelID: "qwen3-tts-12hz-0.6b-base",
            voiceAssetID: assetID,
            text: "生成内容",
            instruct: "自然",
            audioPath: "/outputs/result.wav",
            runtime: "mlx-audio",
            status: .ready,
            error: nil,
            createdAt: Date(timeIntervalSince1970: 1_800_000_012)
        )
    )

    #expect(recordingID == "recording-1")
    #expect(try store.listVoiceAssets().first?.id == assetID)
    #expect(try store.listReferenceRecordings().first?.duration == 3.2)
    #expect(try store.listGenerations().first?.runtime == "mlx-audio")
}

@Test func sqliteStoreDeletesGenerationAndOnlyDeletesWorkspaceAudioWhenRequested() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let dbURL = root.appendingPathComponent("database/MacQwenVoice.sqlite")
    let output = root.appendingPathComponent("outputs/result.wav")
    let outside = FileManager.default.temporaryDirectory.appendingPathComponent("outside-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: outside) }
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("wav".utf8).write(to: output)
    try Data("outside".utf8).write(to: outside)

    let store = try AppDatabase(path: dbURL.path)
    try store.saveGeneration(
        GenerationRecord(
            id: "generation-1",
            mode: "custom_voice",
            modelID: "qwen3-tts-12hz-0.6b-customvoice",
            text: "生成内容",
            audioPath: output.path,
            runtime: "mlx-audio",
            status: .ready
        )
    )
    try store.saveGeneration(
        GenerationRecord(
            id: "generation-2",
            mode: "custom_voice",
            modelID: "qwen3-tts-12hz-0.6b-customvoice",
            text: "外部路径",
            audioPath: outside.path,
            runtime: "mlx-audio",
            status: .ready
        )
    )

    try store.deleteGeneration(id: "generation-1", workspaceRoot: root.path, deleteFile: false)
    #expect(FileManager.default.fileExists(atPath: output.path))
    #expect(!(try store.listGenerations()).contains { $0.id == "generation-1" })

    try store.deleteGeneration(id: "generation-2", workspaceRoot: root.path, deleteFile: true)
    #expect(FileManager.default.fileExists(atPath: outside.path))
    #expect(!(try store.listGenerations()).contains { $0.id == "generation-2" })
}

@Test func sqliteStoreDeletesVoiceAndOptionallyWorkspaceFilesOnly() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let dbURL = root.appendingPathComponent("database/MacQwenVoice.sqlite")
    let reference = root.appendingPathComponent("references/ref.wav")
    let prompt = root.appendingPathComponent("clone_prompts/ref.json")
    let outside = FileManager.default.temporaryDirectory.appendingPathComponent("outside-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: outside) }
    try FileManager.default.createDirectory(at: reference.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: prompt.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("wav".utf8).write(to: reference)
    try Data("prompt".utf8).write(to: prompt)
    try Data("outside".utf8).write(to: outside)

    let store = try AppDatabase(path: dbURL.path)
    _ = try store.saveVoice(
        VoiceProfile(
            id: "clone-1",
            name: "克隆音色",
            kind: .clonedVoice,
            language: "Chinese",
            instruct: "自然",
            referenceAudioPath: reference.path,
            referenceText: "参考文本",
            consentID: "consent-1"
        )
    )
    _ = try store.saveVoiceAsset(
        VoiceAsset(
            id: "clone-1",
            type: .clonedVoice,
            speaker: "克隆音色",
            language: "Chinese",
            instruct: "自然",
            refAudioPath: outside.path,
            refText: "参考文本",
            clonePromptPath: prompt.path,
            consentID: "consent-1"
        )
    )

    try store.deleteVoice(id: "clone-1", workspaceRoot: root.path, deleteFiles: true)

    #expect(try store.listVoices().isEmpty)
    #expect(try store.listVoiceAssets().isEmpty)
    #expect(!FileManager.default.fileExists(atPath: reference.path))
    #expect(!FileManager.default.fileExists(atPath: prompt.path))
    #expect(FileManager.default.fileExists(atPath: outside.path))
}

@Test func sqliteStoreRenamesClonedVoiceAndVoiceAssetSpeaker() throws {
    let dbURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("sqlite")
    defer { try? FileManager.default.removeItem(at: dbURL) }

    let store = try AppDatabase(path: dbURL.path)
    _ = try store.saveVoice(
        VoiceProfile(
            id: "clone-1",
            name: "旧名称",
            kind: .clonedVoice,
            language: "Chinese",
            instruct: "自然"
        )
    )
    _ = try store.saveVoiceAsset(
        VoiceAsset(
            id: "clone-1",
            type: .clonedVoice,
            speaker: "旧名称",
            language: "Chinese",
            instruct: "自然"
        )
    )

    try store.renameVoice(id: "clone-1", name: "新名称")

    #expect(try store.listVoices().first { $0.id == "clone-1" }?.name == "新名称")
    #expect(try store.listVoiceAssets().first { $0.id == "clone-1" }?.speaker == "新名称")
}

@Test func sqliteStoreKeepsFilesStillReferencedByAnotherVoice() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let dbURL = root.appendingPathComponent("database/MacQwenVoice.sqlite")
    let sharedReference = root.appendingPathComponent("references/shared.wav")
    try FileManager.default.createDirectory(at: sharedReference.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("shared".utf8).write(to: sharedReference)

    let store = try AppDatabase(path: dbURL.path)
    for id in ["clone-1", "clone-2"] {
        _ = try store.saveVoice(
            VoiceProfile(
                id: id,
                name: id,
                kind: .clonedVoice,
                language: "Chinese",
                instruct: "自然",
                referenceAudioPath: sharedReference.path,
                referenceText: "参考文本"
            )
        )
        _ = try store.saveVoiceAsset(
            VoiceAsset(
                id: id,
                type: .clonedVoice,
                speaker: id,
                language: "Chinese",
                instruct: "自然",
                refAudioPath: sharedReference.path,
                refText: "参考文本"
            )
        )
    }

    try store.deleteVoice(id: "clone-1", workspaceRoot: root.path, deleteFiles: true)

    #expect(try store.listVoices().map(\.id) == ["clone-2"])
    #expect(FileManager.default.fileExists(atPath: sharedReference.path))
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
