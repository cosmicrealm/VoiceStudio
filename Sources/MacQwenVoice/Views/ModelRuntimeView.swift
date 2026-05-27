import AppKit
import MacQwenVoiceCore
import SwiftUI

struct ModelRuntimeView: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        List {
            Section(viewModel.localized(.modelWorkspaceTitle)) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.usesDefaultWorkspace ? viewModel.localized(.modelDefaultWorkspace) : viewModel.localized(.modelCustomWorkspace))
                            .font(.headline)
                        Text(viewModel.paths.root.path)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                        Text(viewModel.localized(.modelDefaultPathFormat, viewModel.defaultWorkspacePath))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            viewModel.chooseWorkspaceDirectory()
                        } label: {
                            Label(viewModel.localized(.modelChooseWorkspace), systemImage: "folder.badge.gearshape")
                        }
                        Button {
                            viewModel.resetToDefaultWorkspace()
                        } label: {
                            Label(viewModel.localized(.modelResetDefault), systemImage: "arrow.uturn.backward.circle")
                        }
                        .disabled(viewModel.usesDefaultWorkspace)
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([viewModel.paths.root])
                        } label: {
                            Label(viewModel.localized(.modelOpenInFinder), systemImage: "folder")
                        }
                    }
                }
                Text(viewModel.localized(.modelWorkspaceDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(viewModel.localized(.modelRuntimeHealth)) {
                HStack {
                    RuntimeStatusPill()
                    Spacer()
                    Button {
                        viewModel.refreshRuntimeHealth()
                    } label: {
                        Label(viewModel.localized(.modelRecheck), systemImage: "arrow.clockwise")
                    }
                }
                Text(viewModel.runtimeHealth.message)
                    .foregroundStyle(viewModel.runtimeHealth.realInferenceAvailable ? (viewModel.runtimeHealth.audioToolsAvailable ? StudioTheme.success : StudioTheme.warning) : StudioTheme.danger)
                    .textSelection(.enabled)
                runtimeInstallControls
                hardwareGrid
                dependencyGrid
                optionalDependencyGrid
            }

            Section(viewModel.localized(.modelDownloadSource)) {
                Picker(viewModel.localized(.modelDownloadSource), selection: $viewModel.huggingFaceEndpoint) {
                    Text(viewModel.localized(.commonHFMirror)).tag(HuggingFaceDownloadPlan.mirrorEndpoint)
                    Text(viewModel.localized(.commonOfficialSource)).tag(HuggingFaceDownloadPlan.officialEndpoint)
                }
                .pickerStyle(.segmented)
                TextField(viewModel.localized(.modelCustomEndpointPlaceholder), text: $viewModel.huggingFaceEndpoint)
                    .textFieldStyle(.roundedBorder)
                    .textSelection(.enabled)
                Text(viewModel.huggingFaceEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? viewModel.localized(.modelCurrentSourceOfficial) : viewModel.localized(.modelCurrentSourceFormat, viewModel.huggingFaceEndpoint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            modelSection(viewModel.localized(.modelLiteBundleTitle), models: viewModel.catalog.liteBundle, note: viewModel.localized(.modelLiteBundleNote))
            modelSection(viewModel.localized(.modelProBundleTitle), models: viewModel.catalog.proBundle, note: viewModel.localized(.modelProBundleNote))
            modelSection(viewModel.localized(.modelDesignBundleTitle), models: viewModel.catalog.advancedBundle, note: viewModel.localized(.modelDesignBundleNote))
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

    private var runtimeInstallControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.runtimeHealth.needsRuntimeRepair {
                Text(viewModel.localized(.runtimeInstallFirstUse))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if viewModel.runtimeHealth.realInferenceAvailable, !viewModel.runtimeHealth.audioToolsAvailable {
                    Text(viewModel.localized(.runtimeInstallAudioToolWarning))
                        .font(.caption)
                        .foregroundStyle(StudioTheme.warning)
                        .textSelection(.enabled)
                }
                if viewModel.runtimeHealth.realInferenceAvailable, !viewModel.runtimeHealth.downloadToolsAvailable {
                    Text(viewModel.localized(.runtimeInstallDownloadToolWarning))
                        .font(.caption)
                        .foregroundStyle(StudioTheme.warning)
                        .textSelection(.enabled)
                }
                Text(viewModel.localized(.runtimeInstallSSLHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                HStack {
                    Button {
                        viewModel.installRuntimeEnvironment()
                    } label: {
                        Label(viewModel.isInstallingRuntime ? viewModel.localized(.runtimeInstallInstalling) : viewModel.localized(.runtimeInstallRepair), systemImage: "wrench.and.screwdriver")
                    }
                    .disabled(viewModel.isInstallingRuntime)
                    if viewModel.isInstallingRuntime {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            if viewModel.isInstallingRuntime || !viewModel.runtimeInstallLog.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(viewModel.localized(.runtimeInstallProgress))
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(viewModel.runtimeInstallPhase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: viewModel.runtimeInstallProgress)
                    Text(viewModel.runtimeInstallLog.isEmpty ? viewModel.localized(.runtimeInstallWaitingOutput) : viewModel.runtimeInstallLog)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .lineLimit(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(StudioTheme.subtleFill)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                DisclosureGroup(viewModel.localized(.runtimeInstallFullLog)) {
                    Text(viewModel.runtimeInstallLog)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption)
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
                DisclosureGroup(viewModel.localized(.runtimeOptionalExtensions)) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(viewModel.runtimeHealth.optionalDependencies.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                            Label(item.value ? "\(item.key) \(viewModel.localized(.modelInstalled))" : "\(item.key) \(viewModel.localized(.modelMissing))", systemImage: item.value ? "checkmark.circle" : "circle")
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
                            Label(availability.available ? viewModel.localized(.modelInstalled) : viewModel.localized(.modelDownload), systemImage: availability.available ? "checkmark.circle.fill" : "arrow.down.circle")
                        }
                        .disabled(availability.available)
                        Button {
                            viewModel.markModelReady(model)
                        } label: {
                            Label(viewModel.localized(.modelUseDefaultPath), systemImage: "checkmark.circle")
                        }
                        Button {
                            viewModel.chooseModelDirectory(for: model)
                        } label: {
                            Label(viewModel.localized(.modelChooseLocalPath), systemImage: "folder")
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
                Text(viewModel.localized(.modelPrecisionTitle))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.localized(.modelCurrentValueFormat, viewModel.activeModelPrecisionTitle(for: model)))
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
                            Text(ready ? viewModel.localized(.modelInstalled) : viewModel.localized(.modelMissing))
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
                            Label(selected ? viewModel.localized(.modelUsingThisVersion) : viewModel.localized(.modelUseThisVersion), systemImage: selected ? "checkmark" : "arrow.right.circle")
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
