import MacQwenVoiceCore
import SwiftUI

struct TextRobustnessView: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let onOpenScriptStudio: () -> Void

    private let samples = TextRobustnessSample.defaultSamples

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                StudioPanel {
                    StudioSectionHeader(viewModel.localized(.pageTextRobustnessTitle), subtitle: viewModel.localized(.pageTextRobustnessSubtitle))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(samples) { sample in
                    StudioPanel {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sample.title)
                                    .font(.headline)
                                Text(sample.text)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                viewModel.text = sample.text
                                viewModel.updateSegments()
                                onOpenScriptStudio()
                            } label: {
                                Label(viewModel.localized(.pageTextRobustnessLoadScriptStudio), systemImage: "arrow.right.doc.on.clipboard")
                            }
                        }
                    }
                }
            }
            .padding(StudioTheme.pagePadding)
        }
    }
}
