import SwiftUI

struct RuntimeStatusPill: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        let activeModelID = viewModel.activeGenerationModelID
        let availability = viewModel.modelAvailability(for: activeModelID)
        let inferenceReady = viewModel.runtimeHealth.realInferenceAvailable
        let runtimeReady = inferenceReady && viewModel.runtimeHealth.audioToolsAvailable && viewModel.runtimeHealth.downloadToolsAvailable
        let ready = runtimeReady && availability.available
        StudioPill(
            title: ready
                ? viewModel.localized(.runtimeStatusRealInference)
                : (runtimeReady
                    ? viewModel.localized(.runtimeStatusModelNotReady)
                    : (inferenceReady ? missingToolTitle : viewModel.localized(.runtimeStatusUnavailable))),
            systemImage: ready ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
            color: ready ? StudioTheme.success : StudioTheme.warning
        )
        .layoutPriority(2)
        .help(runtimeReady ? "\(viewModel.runtimeHealth.message); active model \(activeModelID); \(availability.label): \(availability.path)" : viewModel.runtimeHealth.message)
    }

    private var missingToolTitle: String {
        if !viewModel.runtimeHealth.downloadToolsAvailable {
            return viewModel.localized(.runtimeStatusDownloadToolMissing)
        }
        if !viewModel.runtimeHealth.audioToolsAvailable {
            return viewModel.localized(.runtimeStatusAudioToolMissing)
        }
        return viewModel.localized(.runtimeStatusNeedsRepair)
    }
}
