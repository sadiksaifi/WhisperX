import SwiftUI

/// Minimal floating HUD overlay shown during recording and transcription.
/// Displays only a state indicator (icon + one or two words).
struct HUDView: View {
    @Bindable var appState: AppState

    var body: some View {
        statusIndicator
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .clipShape(Capsule())
            .fixedSize()
    }

    /// Status indicator with priority: error > copied > launched > recording > transcribing > idle.
    @ViewBuilder
    private var statusIndicator: some View {
        switch appState.hudFeedback {
        case .error:
            ErrorIndicator()
        case .copied:
            CopiedIndicator()
        case .launched:
            LaunchedIndicator()
        case .none:
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
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            Text("Listening...")
                .font(.body)
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
                .font(.body)
        }
    }
}

// MARK: - Copied Indicator

/// Indicator shown briefly after successful clipboard copy.
private struct CopiedIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Copied")
                .font(.body)
        }
    }
}

// MARK: - Error Indicator

/// Brief error indicator shown when transcription fails.
private struct ErrorIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            Text("Error")
                .font(.body)
        }
    }
}

// MARK: - Launched Indicator

/// Indicator shown briefly when app first launches.
private struct LaunchedIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("WhisperX")
                .font(.body)
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

#Preview("Copied") {
    HUDView(appState: {
        let state = AppState()
        state.hudFeedback = .copied
        return state
    }())
}

#Preview("Error") {
    HUDView(appState: {
        let state = AppState()
        state.hudFeedback = .error
        return state
    }())
}
