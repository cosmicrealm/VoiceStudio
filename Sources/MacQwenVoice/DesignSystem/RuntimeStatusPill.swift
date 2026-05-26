import SwiftUI

struct RuntimeStatusPill: View {
    @EnvironmentObject private var viewModel: StudioViewModel

    var body: some View {
        let activeModelID = viewModel.activeGenerationModelID
        let availability = viewModel.modelAvailability(for: activeModelID)
        let inferenceReady = viewModel.runtimeHealth.realInferenceAvailable
        let runtimeReady = inferenceReady && viewModel.runtimeHealth.audioToolsAvailable
        let ready = runtimeReady && availability.available
        StudioPill(
            title: ready ? "真实推理" : (runtimeReady ? "模型未就绪" : (inferenceReady ? "音频工具缺失" : "运行时不可用")),
            systemImage: ready ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
            color: ready ? StudioTheme.success : StudioTheme.warning
        )
        .layoutPriority(2)
        .help(runtimeReady ? "\(viewModel.runtimeHealth.message)；当前生效模型 \(activeModelID)；\(availability.label)：\(availability.path)" : viewModel.runtimeHealth.message)
    }
}
