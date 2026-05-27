import MacQwenVoiceCore
import SwiftUI

struct VoiceToolsView: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerPanel
                audioMergePanel
                mergedResultPanel
            }
            .padding(StudioTheme.pagePadding)
        }
        .background(StudioTheme.workspaceBackground)
    }

    private var headerPanel: some View {
        StudioPanel {
            HStack(alignment: .center) {
                StudioSectionHeader("Voice Tools", subtitle: viewModel.localized(.pageVoiceToolsSubtitle))
                Spacer()
                StudioPill(title: viewModel.localized(.pageVoiceToolsLocalProcessing), systemImage: "lock", color: StudioTheme.success)
            }
        }
    }

    private var audioMergePanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    StudioSectionHeader(viewModel.localized(.voiceToolsMergeTitle), subtitle: viewModel.localized(.voiceToolsMergeSubtitle))
                    Spacer()
                    Button {
                        viewModel.chooseVoiceToolsAudioFiles()
                    } label: {
                        Label(viewModel.localized(.commonAddAudio), systemImage: "plus")
                    }
                    Button {
                        viewModel.clearVoiceToolsAudioItems()
                    } label: {
                        Label(viewModel.localized(.commonClear), systemImage: "xmark.circle")
                    }
                    .disabled(viewModel.voiceToolsAudioMergeItems.isEmpty)
                }

                if viewModel.voiceToolsAudioMergeItems.isEmpty {
                    emptyMergeList
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(viewModel.voiceToolsAudioMergeItems.enumerated()), id: \.element.id) { index, item in
                            audioItemRow(index: index, item: item)
                        }
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.localized(.commonOutputFileName))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("voice-tools-merged.webm", text: $viewModel.voiceToolsPageDraft.outputName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 260)
                    }
                    Button {
                        viewModel.mergeVoiceToolsAudioFiles(outputName: viewModel.voiceToolsPageDraft.outputName)
                    } label: {
                        Label(viewModel.isMergingVoiceToolsAudio ? viewModel.localized(.voiceToolsMerging) : viewModel.localized(.voiceToolsMergeButton), systemImage: "waveform.path")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isMergingVoiceToolsAudio || viewModel.voiceToolsAudioMergeItems.count < 2)
                    Spacer()
                    Text(viewModel.voiceToolsStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var emptyMergeList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(viewModel.localized(.voiceToolsEmptyTitle), systemImage: "waveform")
                .font(.headline)
            Text(viewModel.localized(.voiceToolsEmptySubtitle))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioCardStyle()
    }

    private func audioItemRow(index: Int, item: VoiceToolsAudioMergeItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(index + 1)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.fileName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.originalPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .textSelection(.enabled)
                Text(viewModel.audioDurationLabel(path: item.workspacePath))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            AudioPlayButton(
                viewModel.localized(.commonPreview),
                item: AudioPlaybackItem.file(path: item.workspacePath, context: "voice-tools-item-\(item.id)")
            )
            Button {
                viewModel.moveVoiceToolsAudioItem(item, by: -1)
            } label: {
                Label(viewModel.localized(.commonMoveUp), systemImage: "chevron.up")
            }
            .disabled(index == 0)
            Button {
                viewModel.moveVoiceToolsAudioItem(item, by: 1)
            } label: {
                Label(viewModel.localized(.commonMoveDown), systemImage: "chevron.down")
            }
            .disabled(index == viewModel.voiceToolsAudioMergeItems.count - 1)
            Button(role: .destructive) {
                viewModel.removeVoiceToolsAudioItem(item)
            } label: {
                Label(viewModel.localized(.voiceToolsRemove), systemImage: "trash")
            }
        }
        .buttonStyle(.bordered)
        .padding(12)
        .background(StudioTheme.subtleFill)
        .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
    }

    private var mergedResultPanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 12) {
                StudioSectionHeader(viewModel.localized(.voiceToolsResultTitle), subtitle: viewModel.localized(.voiceToolsResultSubtitle))
                if let path = viewModel.voiceToolsMergedAudioPath {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        HStack {
                            StudioPill(title: viewModel.audioDurationLabel(path: path), systemImage: "timer", color: .secondary)
                            Spacer()
                            AudioPlayButton(
                                viewModel.localized(.voiceToolsPlayMerged),
                                pauseTitle: viewModel.localized(.voiceToolsPauseMerged),
                                item: AudioPlaybackItem.file(path: path, context: "voice-tools-merged")
                            )
                            Button {
                                viewModel.exportVoiceToolsMergedAudio(defaultName: viewModel.voiceToolsPageDraft.outputName)
                            } label: {
                                Label(viewModel.localized(.commonExport), systemImage: "square.and.arrow.up")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .studioCardStyle()
                } else {
                    Text(viewModel.localized(.voiceToolsResultEmpty))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .studioCardStyle()
                }
            }
        }
    }
}
