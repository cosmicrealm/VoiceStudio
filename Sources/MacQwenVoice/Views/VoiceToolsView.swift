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
                StudioSectionHeader("Voice Tools", subtitle: "独立音频工具箱；导入主流音频后统一转码并按顺序合并。")
                Spacer()
                StudioPill(title: "本地处理", systemImage: "lock", color: StudioTheme.success)
            }
        }
    }

    private var audioMergePanel: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    StudioSectionHeader("按顺序合并音频", subtitle: "选择多个音频后按列表顺序合并；支持 wav、mp3、m4a、aac、flac、ogg、opus、aiff、caf、webm，扩展名大小写不敏感。")
                    Spacer()
                    Button {
                        viewModel.chooseVoiceToolsAudioFiles()
                    } label: {
                        Label("添加音频", systemImage: "plus")
                    }
                    Button {
                        viewModel.clearVoiceToolsAudioItems()
                    } label: {
                        Label("清空", systemImage: "xmark.circle")
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
                        Text("输出文件名")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("voice-tools-merged.webm", text: $viewModel.voiceToolsPageDraft.outputName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 260)
                    }
                    Button {
                        viewModel.mergeVoiceToolsAudioFiles(outputName: viewModel.voiceToolsPageDraft.outputName)
                    } label: {
                        Label(viewModel.isMergingVoiceToolsAudio ? "合并中" : "合并为总音频", systemImage: "waveform.path")
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
            Label("还没有待合并音频", systemImage: "waveform")
                .font(.headline)
            Text("点击“添加音频”选择一组文件；如果顺序不对，可以在列表中用上移/下移调整。")
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
                "试听",
                item: AudioPlaybackItem.file(path: item.workspacePath, context: "voice-tools-item-\(item.id)")
            )
            Button {
                viewModel.moveVoiceToolsAudioItem(item, by: -1)
            } label: {
                Label("上移", systemImage: "chevron.up")
            }
            .disabled(index == 0)
            Button {
                viewModel.moveVoiceToolsAudioItem(item, by: 1)
            } label: {
                Label("下移", systemImage: "chevron.down")
            }
            .disabled(index == viewModel.voiceToolsAudioMergeItems.count - 1)
            Button(role: .destructive) {
                viewModel.removeVoiceToolsAudioItem(item)
            } label: {
                Label("移除", systemImage: "trash")
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
                StudioSectionHeader("合并结果", subtitle: "生成后的总音频会保存在当前 workspace 的 outputs 目录。")
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
                                "播放总音频",
                                pauseTitle: "暂停总音频",
                                item: AudioPlaybackItem.file(path: path, context: "voice-tools-merged")
                            )
                            Button {
                                viewModel.exportVoiceToolsMergedAudio(defaultName: viewModel.voiceToolsPageDraft.outputName)
                            } label: {
                                Label("导出", systemImage: "square.and.arrow.up")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .studioCardStyle()
                } else {
                    Text("合并完成后会显示总音频路径，并提供播放和导出。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .studioCardStyle()
                }
            }
        }
    }
}
