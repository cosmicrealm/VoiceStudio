import MacQwenVoiceCore
import SwiftUI

struct GenerationResultsPanel: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    private let pageSize = 5
    private let maxPageButtons = 5

    var body: some View {
        let pagination = GenerationResultsPagination(
            totalItems: viewModel.generationHistory.count,
            pageSize: pageSize,
            currentPage: viewModel.scriptStudioPageDraft.generationResultsPage
        )

        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    runningSection
                    resultSection(pagination)
                    paginationFooter(pagination)
                }
                .padding(StudioTheme.pagePadding)
            }
        }
        .background(StudioTheme.workspaceBackground)
        .onChange(of: viewModel.generationHistory.count) { _, _ in
            goToPage(viewModel.scriptStudioPageDraft.generationResultsPage)
        }
    }

    private var header: some View {
        HStack {
            StudioSectionHeader("生成结果", subtitle: "共 \(viewModel.generationHistory.count) 条 · 每页 \(pageSize) 条")
            Spacer()
        }
        .padding(.horizontal, StudioTheme.pagePadding)
        .padding(.vertical, 16)
        .background(StudioTheme.panelBackground)
    }

    @ViewBuilder
    private var runningSection: some View {
        if !viewModel.generatingSegmentIDs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                StudioSectionHeader("正在生成")
                ForEach(viewModel.segments.filter { viewModel.generatingSegmentIDs.contains($0.id) }) { segment in
                    GeneratingSegmentCard(segment: segment)
                }
            }
        }
    }

    private func resultSection(_ pagination: GenerationResultsPagination) -> some View {
        let records = pagedRecords(pagination)
        return VStack(alignment: .leading, spacing: 10) {
            if records.isEmpty {
                emptyState
            }
            ForEach(Array(records.enumerated()), id: \.element.id) { offset, record in
                AudioResultRow(
                    record: record,
                    sequenceLabel: ChineseOrdinalFormatter.item(pagination.itemRange.lowerBound + offset + 1)
                )
            }
        }
    }

    private func paginationFooter(_ pagination: GenerationResultsPagination) -> some View {
        paginationControls(pagination)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var emptyState: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label("还没有生成结果", systemImage: "waveform")
                    .font(.headline)
                Text("点击左侧“生成全文”后，最新生成会出现在这里。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func paginationControls(_ pagination: GenerationResultsPagination) -> some View {
        HStack(spacing: 8) {
            Button {
                goToPage(1)
            } label: {
                Image(systemName: "backward.end")
            }
            .disabled(pagination.currentPage == 1)

            Button {
                goToPage(pagination.currentPage - 1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(pagination.currentPage == 1)

            ForEach(pagination.visiblePageNumbers(maxVisible: maxPageButtons), id: \.self) { pageNumber in
                if pageNumber == pagination.currentPage {
                    Button("\(pageNumber)") {
                        goToPage(pageNumber)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("\(pageNumber)") {
                        goToPage(pageNumber)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button {
                goToPage(pagination.currentPage + 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(pagination.currentPage == pagination.totalPages)

            Button {
                goToPage(pagination.totalPages)
            } label: {
                Image(systemName: "forward.end")
            }
            .disabled(pagination.currentPage == pagination.totalPages)

            Divider()
                .frame(height: 20)

            Text("跳到")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("页码", text: $viewModel.scriptStudioPageDraft.generationResultsJumpPageText)
                .frame(width: 54)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    jumpToTypedPage(pagination)
                }
            Text("/ \(pagination.totalPages)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("跳转") {
                jumpToTypedPage(pagination)
            }
        }
        .controlSize(.regular)
    }

    private func goToPage(_ targetPage: Int) {
        let pagination = GenerationResultsPagination(
            totalItems: viewModel.generationHistory.count,
            pageSize: pageSize,
            currentPage: targetPage
        )
        viewModel.scriptStudioPageDraft.generationResultsPage = pagination.currentPage
        viewModel.scriptStudioPageDraft.generationResultsJumpPageText = "\(pagination.currentPage)"
    }

    private func jumpToTypedPage(_ pagination: GenerationResultsPagination) {
        let targetPage = Int(viewModel.scriptStudioPageDraft.generationResultsJumpPageText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? pagination.currentPage
        goToPage(targetPage)
    }

    private func pagedRecords(_ pagination: GenerationResultsPagination) -> [GenerationRecord] {
        Array(viewModel.generationHistory[pagination.itemRange])
    }
}

private struct GeneratingSegmentCard: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let segment: TextSegment

    var body: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(segment.text)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                ProgressView(value: viewModel.generationProgress[segment.id] ?? 0, total: 1)
                    .progressViewStyle(.linear)
                HStack {
                    Text(viewModel.generationProgressLabel[segment.id] ?? "准备生成")
                    Spacer()
                    Text("\(Int(((viewModel.generationProgress[segment.id] ?? 0) * 100).rounded()))%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AudioResultRow: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let record: GenerationRecord
    let sequenceLabel: String
    @State private var showDetails = false

    var body: some View {
        StudioPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Text(sequenceLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.text)
                            .font(.headline)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            StudioPill(title: shortModelName, systemImage: "cpu", color: .secondary)
                            StudioPill(title: record.runtime.isEmpty ? record.status.rawValue : record.runtime, systemImage: "waveform", color: record.status == .ready ? StudioTheme.success : StudioTheme.warning)
                        }
                    }
                    Spacer()
                    actionButtons
                }

                Text("prompt: \(record.instruct.isEmpty ? "未设置" : record.instruct)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(showDetails ? nil : 2)

                Slider(
                    value: Binding(
                        get: { viewModel.audioPlaybackProgress[record.id] ?? 0 },
                        set: { viewModel.seekPlayback(record: record, progress: $0) }
                    ),
                    in: 0...1
                )
                .disabled(record.audioPath.isEmpty || record.status != .ready)

                HStack {
                    Text(viewModel.audioDurationLabel(audioID: record.id, path: record.audioPath))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(showDetails ? "收起详情" : "显示详情") {
                        showDetails.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    Spacer()
                }

                if showDetails {
                    VStack(alignment: .leading, spacing: 5) {
                        if !record.audioPath.isEmpty {
                            Text(record.audioPath)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        if let error = record.error, !error.isEmpty {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(StudioTheme.danger)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.togglePlay(record: record)
            } label: {
                Label(viewModel.isPlaying(record: record) ? "暂停" : "播放", systemImage: viewModel.isPlaying(record: record) ? "pause.circle" : "play.circle")
            }
            .disabled(record.audioPath.isEmpty || record.status != .ready)
            Button {
                viewModel.export(record: record)
            } label: {
                Label("导出", systemImage: "square.and.arrow.up")
            }
            .disabled(record.audioPath.isEmpty || record.status != .ready)
            Button(role: .destructive) {
                viewModel.deleteGeneration(record)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .buttonStyle(.bordered)
    }

    private var shortModelName: String {
        record.modelID
            .replacingOccurrences(of: "qwen3-tts-12hz-", with: "")
            .replacingOccurrences(of: "-", with: " ")
    }
}
