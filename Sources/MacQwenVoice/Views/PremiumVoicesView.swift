import MacQwenVoiceCore
import SwiftUI

struct PremiumVoicesView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenScriptStudio: () -> Void

    private var templates: [(AppLocalizationKey, AppLocalizationKey)] {
        [
            (.premiumTemplateNatural, .premiumTemplateNaturalInstruction),
            (.premiumTemplateEmotional, .premiumTemplateEmotionalInstruction),
            (.premiumTemplateSlowClear, .premiumTemplateSlowClearInstruction),
            (.premiumTemplateCharacter, .premiumTemplateCharacterInstruction)
        ]
    }

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
                StudioSectionHeader(viewModel.localized(.pagePremiumTitle), subtitle: viewModel.localized(.pagePremiumSubtitle))
                Spacer()
                StudioPill(title: viewModel.localized(.premiumSpeakerCountFormat, "\(viewModel.builtinVoices.count)"), systemImage: "person.wave.2", color: Color.accentColor)
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
                        Button(viewModel.localized(template.0)) {
                            viewModel.selectVoice(voice)
                            viewModel.instruct = viewModel.localized(template.1)
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
                    Label(viewModel.localized(.pagePremiumUseForGeneration), systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
