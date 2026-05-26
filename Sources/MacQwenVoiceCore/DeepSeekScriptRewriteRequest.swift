import Foundation

public struct DeepSeekScriptRewriteRequest: Equatable, Sendable {
    public let sourceText: String
    public let contextSummary: String
    public let stylePrompt: String

    public init(
        sourceText: String,
        contextSummary: String = "",
        stylePrompt: String = ""
    ) {
        self.sourceText = sourceText
        self.contextSummary = contextSummary
        self.stylePrompt = stylePrompt
    }

    public var requestBody: [String: Any] {
        [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    你是 Voice Studio 的小说转多角色对话脚本改写器。你的任务是把输入文本改写成适合 Qwen3-TTS 逐段生成的对话脚本。

                    必须输出 JSON，不要输出 Markdown，不要解释。JSON 顶层必须包含：
                    {
                      "roles": [{"name": "旁白", "voice_hint": "声音建议"}],
                      "script_text": "旁白: ...\\n角色名: ...",
                      "warnings": [],
                      "coverage_warnings": []
                    }

                    改写规则：
                    1. script_text 每一行必须是“角色名: 内容”。
                    2. 必须保持原意，不能删减原始文本的信息点；不得摘要式压缩，不得把事实、动作、心理、人物关系或关键情绪省略。
                    3. 可以为了对话合理性拆分、重排和口语化，但每个原始信息点都必须在旁白或角色台词中得到承接。
                    4. 连续旁白必须合并；合并后仍要覆盖原文信息，避免出现很多零碎旁白。
                    5. 删除音效、镜头、舞台说明、括号说明的呈现形式，不能直接作为“音效”输出；如果其中包含剧情信息，要改写为旁白或角色可说的话。
                    6. 旁白只负责环境、动作、心理、时间跳转和必要信息。
                    7. 人物台词负责冲突推进，必须保留原文人物关系和情绪。
                    8. 不要添加原文没有支撑的重大剧情。
                    9. 角色名必须短、稳定、无数字、无空格、少于 20 个字。
                    10. 如果原文人物名明确，使用原人物名；如果不明确，用 角色A、角色B。
                    11. 默认角色包括旁白；不要使用“音效”角色。
                    12. 单行不要过长，尽量控制在 15 到 120 个汉字，便于逐段合成。
                    13. 如果输入文本过长，只改写当前片段，不要续写后文；如确实无法完整覆盖，在 coverage_warnings 中说明。
                    """
                ],
                [
                    "role": "user",
                    "content": """
                    请把下面文本改写成 Voice Studio 可用的多角色对话脚本。

                    目标：
                    - 风格：\(stylePrompt.isEmpty ? "科幻、克制、沉浸式" : stylePrompt)
                    - 旁白密度：中等
                    - 台词改写强度：保留原意，适度口语化
                    - 是否保留人物名：是
                    - 输出语言：中文
                    - 禁止音效：是
                    - 禁止 Markdown：是

                    上文摘要：
                    \(contextSummary.isEmpty ? "无" : contextSummary)

                    当前待改写文本：
                    \(sourceText)
                    """
                ]
            ],
            "response_format": [
                "type": "json_object"
            ],
            "temperature": 0.45,
            "max_tokens": 4096
        ]
    }
}

public struct DeepSeekScriptRewriteRole: Equatable, Sendable {
    public var name: String
    public var voiceHint: String

    public init(name: String, voiceHint: String) {
        self.name = name
        self.voiceHint = voiceHint
    }
}

public struct DeepSeekScriptRewriteResult: Equatable, Sendable {
    public var roles: [DeepSeekScriptRewriteRole]
    public var scriptText: String
    public var warnings: [String]

    public init(
        roles: [DeepSeekScriptRewriteRole],
        scriptText: String,
        warnings: [String]
    ) {
        self.roles = roles
        self.scriptText = scriptText
        self.warnings = warnings
    }
}

public enum DeepSeekScriptRewriteResponse {
    public static func parse(content: String) throws -> DeepSeekScriptRewriteResult {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NSError(domain: "DeepSeekScriptRewrite", code: -1, userInfo: [NSLocalizedDescriptionKey: "对话改写结果为空"])
        }
        guard
            let json = jsonObjectString(from: trimmed),
            let data = json.data(using: .utf8),
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw NSError(domain: "DeepSeekScriptRewrite", code: -2, userInfo: [NSLocalizedDescriptionKey: "对话改写结果不是有效 JSON"])
        }
        let scriptText = (object["script_text"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scriptText.isEmpty else {
            throw NSError(domain: "DeepSeekScriptRewrite", code: -3, userInfo: [NSLocalizedDescriptionKey: "对话脚本为空"])
        }
        let roleNames = SpeakerTaggedTextNormalizer.roleNames(from: scriptText)
        guard !roleNames.isEmpty else {
            throw NSError(domain: "DeepSeekScriptRewrite", code: -4, userInfo: [NSLocalizedDescriptionKey: "对话脚本没有可识别的角色标签"])
        }

        let roles = parseRoles(object["roles"], fallbackRoleNames: roleNames)
        let warnings = (object["warnings"] as? [Any] ?? [])
            .compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let coverageWarnings = (object["coverage_warnings"] as? [Any] ?? [])
            .compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return DeepSeekScriptRewriteResult(
            roles: roles,
            scriptText: scriptText,
            warnings: warnings + coverageWarnings
        )
    }

    private static func parseRoles(_ value: Any?, fallbackRoleNames: [String]) -> [DeepSeekScriptRewriteRole] {
        let parsed = (value as? [[String: Any]] ?? []).compactMap { item -> DeepSeekScriptRewriteRole? in
            let name = (item["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let voiceHint = (item["voice_hint"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return DeepSeekScriptRewriteRole(name: name, voiceHint: voiceHint)
        }
        if !parsed.isEmpty {
            return parsed
        }
        return fallbackRoleNames.map { DeepSeekScriptRewriteRole(name: $0, voiceHint: "") }
    }

    private static func jsonObjectString(from content: String) -> String? {
        if content.hasPrefix("{"), content.hasSuffix("}") {
            return content
        }
        guard
            let start = content.firstIndex(of: "{"),
            let end = content.lastIndex(of: "}")
        else {
            return nil
        }
        return String(content[start...end])
    }
}
