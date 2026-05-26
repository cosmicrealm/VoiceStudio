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
                    StudioSectionHeader("文本鲁棒性样例", subtitle: "用于快速检查符号、拼音、公式、跨语言文本的生成稳定性。")
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
                                Label("载入 Script Studio", systemImage: "arrow.right.doc.on.clipboard")
                            }
                        }
                    }
                }
            }
            .padding(StudioTheme.pagePadding)
        }
    }
}
