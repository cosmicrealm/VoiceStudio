import MacQwenVoiceCore
import SwiftUI

struct AudioPlayButton: View {
    @EnvironmentObject private var viewModel: StudioViewModel
    let title: String
    let pauseTitle: String
    let item: AudioPlaybackItem?

    init(_ title: String, pauseTitle: String = "", item: AudioPlaybackItem?) {
        self.title = title
        self.pauseTitle = pauseTitle
        self.item = item
    }

    var body: some View {
        Button {
            if let item {
                viewModel.togglePlay(audioItem: item)
            }
        } label: {
            Label(labelTitle, systemImage: isPlaying ? "pause.circle" : "play.circle")
        }
        .disabled(item == nil)
    }

    private var isPlaying: Bool {
        guard let item else { return false }
        return viewModel.isPlaying(audioItem: item)
    }

    private var labelTitle: String {
        isPlaying ? (pauseTitle.isEmpty ? viewModel.localized(.commonPause) : pauseTitle) : title
    }
}
