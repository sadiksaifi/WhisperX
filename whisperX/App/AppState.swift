import Foundation

/// Runtime application state shared across the app.
/// Holds transient state that doesn't persist between launches.
@Observable
@MainActor
final class AppState {
    /// Current recording/transcription status.
    var recordingState: RecordingState = .idle

    /// The most recent transcription result, if any.
    var lastTranscription: String?

    /// Whether the model is currently loading.
    var isModelLoading: Bool = false

    /// Model download progress (0.0 to 1.0), nil if not downloading.
    /// Used by Settings UI to show download progress.
    var modelDownloadProgress: Double?

    /// Error message to display, if any.
    var errorMessage: String?

    /// URL of the most recent audio recording, if any.
    /// Set after recording stops, used by the transcription pipeline.
    var lastRecordingURL: URL?

    /// Current HUD feedback to display (copied confirmation or error).
    var hudFeedback: HUDFeedbackState = .none

    /// Clears any transient error state.
    func clearError() {
        errorMessage = nil
    }

    /// Shows "Copied" feedback in HUD and auto-clears after delay.
    func showCopiedFeedback() {
        hudFeedback = .copied
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if hudFeedback == .copied { hudFeedback = .none }
        }
    }

    /// Shows brief error feedback in HUD and auto-clears after delay.
    func showErrorFeedback() {
        hudFeedback = .error
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if hudFeedback == .error { hudFeedback = .none }
        }
    }
}

// MARK: - HUDFeedbackState

/// HUD display state after transcription completes.
enum HUDFeedbackState: Equatable, Sendable {
    /// No feedback to display.
    case none
    /// Show green checkmark + "Copied" confirmation.
    case copied
    /// Show red dot + "Error" indicator.
    case error
}

// MARK: - RecordingState

/// Represents the current state of the recording pipeline.
enum RecordingState: Equatable, Sendable {
    /// No recording in progress.
    case idle

    /// Actively recording audio.
    case recording

    /// Processing recorded audio through the model.
    case transcribing
}
