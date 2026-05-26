import AppKit
import MacQwenVoiceCore
import SwiftUI

struct ModelRuntimeView: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        List {
            Section("工作目录") {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.usesDefaultWorkspace ? "默认 workspace" : "自定义 workspace")
                            .font(.headline)
                        Text(viewModel.paths.root.path)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                        Text("默认路径：\(viewModel.defaultWorkspacePath)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            viewModel.chooseWorkspaceDirectory()
                        } label: {
                            Label("选择 Workspace", systemImage: "folder.badge.gearshape")
                        }
                        Button {
                            viewModel.resetToDefaultWorkspace()
                        } label: {
                            Label("恢复默认", systemImage: "arrow.uturn.backward.circle")
                        }
                        .disabled(viewModel.usesDefaultWorkspace)
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([viewModel.paths.root])
                        } label: {
                            Label("在 Finder 打开", systemImage: "folder")
                        }
                    }
                }
                Text("模型默认下载到当前 workspace/models；你也可以切换整个 workspace，或为单个模型选择已下载路径。切换 workspace 后会重新加载数据库、模型状态和后端运行目录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("运行时健康状态") {
                HStack {
                    RuntimeStatusPill()
                    Spacer()
                    Button {
                        viewModel.refreshRuntimeHealth()
                    } label: {
                        Label("重新检查", systemImage: "arrow.clockwise")
                    }
                }
                Text(viewModel.runtimeHealth.message)
                    .foregroundStyle(viewModel.runtimeHealth.realInferenceAvailable ? StudioTheme.success : StudioTheme.danger)
                    .textSelection(.enabled)
                hardwareGrid
                dependencyGrid
                optionalDependencyGrid
            }

            Section("模型下载源") {
                Picker("下载源", selection: $viewModel.huggingFaceEndpoint) {
                    Text("HF Mirror").tag(HuggingFaceDownloadPlan.mirrorEndpoint)
                    Text("官方源").tag(HuggingFaceDownloadPlan.officialEndpoint)
                }
                .pickerStyle(.segmented)
                TextField("自定义 HF_ENDPOINT，可留空使用官方源", text: $viewModel.huggingFaceEndpoint)
                    .textFieldStyle(.roundedBorder)
                    .textSelection(.enabled)
                Text(viewModel.huggingFaceEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "当前下载源：Hugging Face 官方源" : "当前下载源：\(viewModel.huggingFaceEndpoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            modelSection("Lite 包：0.6B CustomVoice + Base", models: viewModel.catalog.liteBundle, note: "预览和基础机型优先；CustomVoice 用于精品生成，Base 用于克隆生成和对话生成。")
            modelSection("Pro 包：1.7B CustomVoice + Base", models: viewModel.catalog.proBundle, note: "正式导出质量优先；CustomVoice 控制力更强，Base 克隆质量更高。")
            modelSection("Design 包：1.7B VoiceDesign", models: viewModel.catalog.advancedBundle, note: "自然语言声音创造；满意后保存为可复用角色音色。")
        }
    }

    private var dependencyGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(viewModel.runtimeHealth.dependencies.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                Label(item.key, systemImage: item.value ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(item.value ? StudioTheme.success : StudioTheme.danger)
            }
        }
    }

    private var hardwareGrid: some View {
        Group {
            if !viewModel.runtimeHealth.hardware.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(viewModel.runtimeHealth.hardware.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.key)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(item.value)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                        .padding(8)
                        .background(StudioTheme.subtleFill)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                }
            }
        }
    }

    private var optionalDependencyGrid: some View {
        Group {
            if !viewModel.runtimeHealth.optionalDependencies.isEmpty {
                DisclosureGroup("可选扩展") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(viewModel.runtimeHealth.optionalDependencies.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                            Label(item.value ? "\(item.key) 已安装" : "\(item.key) 未安装", systemImage: item.value ? "checkmark.circle" : "circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.caption)
            }
        }
    }

    private func modelSection(_ title: String, models: [QwenModelSpec], note: String) -> some View {
        Section(title) {
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(models) { model in
                let availability = viewModel.modelAvailability(for: model.id)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.displayName)
                                .font(.headline)
                            Text(model.repository)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(model.variant.rawValue) · \(model.capability.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.modelStates[model.id]?.status.rawValue ?? ModelInstallStatus.missing.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Button {
                            viewModel.downloadModel(model)
                        } label: {
                            Label(availability.available ? "已安装" : "下载", systemImage: availability.available ? "checkmark.circle.fill" : "arrow.down.circle")
                        }
                        .disabled(availability.available)
                        Button {
                            viewModel.markModelReady(model)
                        } label: {
                            Label("使用默认路径", systemImage: "checkmark.circle")
                        }
                        Button {
                            viewModel.chooseModelDirectory(for: model)
                        } label: {
                            Label("选择本地路径", systemImage: "folder")
                        }
                        Text(viewModel.downloadCommand(for: model))
                            .textSelection(.enabled)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !model.precisionChoices.isEmpty {
                        precisionSelector(for: model)
                    }
                    Label(availability.label, systemImage: availability.available ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(availability.available ? StudioTheme.success : StudioTheme.warning)
                    Text(availability.path.isEmpty ? viewModel.currentModelPath(for: model) : availability.path)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .textSelection(.enabled)
                    if let log = viewModel.downloadLogs[model.id], !log.isEmpty {
                        Text(log)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func precisionSelector(for model: QwenModelSpec) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("VoiceDesign 精度/版本")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("当前：\(viewModel.activeModelPrecisionTitle(for: model))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(model.precisionChoices) { choice in
                    let ready = viewModel.isModelPrecisionChoiceReady(choice)
                    let selected = viewModel.isModelPrecisionChoiceSelected(choice, for: model)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(choice.title, systemImage: selected ? "checkmark.circle.fill" : "circle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selected ? StudioTheme.success : .primary)
                            Spacer()
                            Text(ready ? "已安装" : "未安装")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(ready ? StudioTheme.success : StudioTheme.warning)
                        }
                        Text(choice.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(choice.localPath(in: viewModel.paths))
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                            .lineLimit(2)
                        Button {
                            viewModel.selectModelPrecisionChoice(choice, for: model)
                        } label: {
                            Label(selected ? "正在使用" : "使用此版本", systemImage: selected ? "checkmark" : "arrow.right.circle")
                        }
                        .disabled(!ready || selected)
                        .controlSize(.small)
                    }
                    .padding(10)
                    .background(StudioTheme.subtleFill)
                    .clipShape(RoundedRectangle(cornerRadius: StudioTheme.cornerRadius, style: .continuous))
                }
            }
        }
        .padding(.top, 4)
    }
}
