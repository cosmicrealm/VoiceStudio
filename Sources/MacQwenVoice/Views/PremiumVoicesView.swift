import MacQwenVoiceCore
import SwiftUI

struct PremiumVoicesView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenScriptStudio: () -> Void

    private let templates: [(String, String)] = [
        ("自然旁白", "自然、清晰、稳定，适合长时间旁白。"),
        ("情绪更强", "情绪更饱满，语气有感染力，但保持吐字清楚。"),
        ("慢速清晰", "语速偏慢，停顿自然，重点词更清晰。"),
        ("角色化", "带有明确 persona，语气更有角色感和画面感。")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.builtinVoices) { voice in
                        voiceCard(voice)
                    }
                }
            }
            .padding(StudioTheme.pagePadding)
        }
    }

    private var pageHeader: some View {
        StudioPanel {
            HStack {
                StudioSectionHeader("CustomVoice 精品音色", subtitle: "用于快速旁白、风格控制和开箱试听。")
                Spacer()
                StudioPill(title: "\(viewModel.builtinVoices.count) 个 speaker", systemImage: "person.wave.2", color: Color.accentColor)
            }
        }
    }

    private func voiceCard(_ voice: VoiceProfile) -> some View {
        StudioPanel {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(BuiltinVoiceDisplayName.displayName(for: voice))
                        .font(.title3.weight(.semibold))
                    Text("\(BuiltinVoiceDisplayName.nativeLanguageLabel(for: voice)) · speaker=\(voice.speaker ?? voice.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)
                HStack(spacing: 8) {
                    ForEach(templates, id: \.0) { template in
                        Button(template.0) {
                            viewModel.selectVoice(voice)
                            viewModel.instruct = template.1
                            onOpenScriptStudio()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                Button {
                    viewModel.selectVoice(voice)
                    onOpenScriptStudio()
                } label: {
                    Label("用于生成", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
