import SwiftUI

/// Floating HUD overlay shown during recording and transcription.
/// Displays the current state and any transcription output.
struct HUDView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            statusIndicator
            if let transcription = appState.lastTranscription {
                Text(transcription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .frame(minWidth: 200, maxWidth: 400)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch appState.recordingState {
        case .idle:
            EmptyView()
        case .recording:
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                Text("Recording...")
                    .font(.headline)
            }
        case .transcribing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing...")
                    .font(.headline)
            }
        }
    }
}

#Preview {
    HUDView(appState: {
        let state = AppState()
        state.recordingState = .recording
        state.lastTranscription = "Hello, this is a test transcription."
        return state
    }())
}
