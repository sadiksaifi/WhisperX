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

    /// Clears any transient error state.
    func clearError() {
        errorMessage = nil
    }
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
