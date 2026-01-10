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
            RecordingIndicator()
        case .transcribing:
            TranscribingIndicator()
        }
    }
}

// MARK: - Recording Indicator

/// Animated indicator shown while recording is in progress.
/// Features a subtle pulsing animation on the recording dot.
private struct RecordingIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            Text("Listening...")
                .font(.headline)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Transcribing Indicator

/// Indicator shown while transcription is in progress.
private struct TranscribingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Transcribing...")
                .font(.headline)
        }
    }
}

// MARK: - Previews

#Preview("Recording") {
    HUDView(appState: {
        let state = AppState()
        state.recordingState = .recording
        return state
    }())
}

#Preview("Transcribing") {
    HUDView(appState: {
        let state = AppState()
        state.recordingState = .transcribing
        return state
    }())
}

#Preview("With Transcription") {
    HUDView(appState: {
        let state = AppState()
        state.recordingState = .recording
        state.lastTranscription = "Hello, this is a test transcription."
        return state
    }())
}
