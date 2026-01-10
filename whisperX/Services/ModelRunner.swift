import Foundation
import WhisperKit
import os

// MARK: - ModelRunnerError

/// Errors that can occur during model operations.
nonisolated enum ModelRunnerError: Error, LocalizedError, Sendable {
    /// The requested model is not downloaded.
    case modelNotInstalled(WhisperModel)

    /// Model initialization failed.
    case modelInitializationFailed(underlying: String)

    /// Audio file not found or inaccessible.
    case audioFileNotFound(URL)

    /// Audio format is invalid or unsupported.
    case invalidAudioFormat(String)

    /// Transcription was cancelled by the user.
    case transcriptionCancelled

    /// Transcription failed during processing.
    case transcriptionFailed(underlying: String)

    /// Insufficient memory to load the model.
    case insufficientMemory(required: Double, available: Double)

    var errorDescription: String? {
        switch self {
        case .modelNotInstalled(let model):
            return "Model '\(model.displayName)' is not installed. Please download it in Settings."
        case .modelInitializationFailed(let error):
            return "Failed to initialize model: \(error)"
        case .audioFileNotFound(let url):
            return "Audio file not found: \(url.lastPathComponent)"
        case .invalidAudioFormat(let reason):
            return "Invalid audio format: \(reason)"
        case .transcriptionCancelled:
            return "Transcription was cancelled."
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error)"
        case .insufficientMemory(let required, let available):
            return String(format: "Insufficient memory. Required: %.1f GB, Available: %.1f GB", required, available)
        }
    }

    /// User-facing recovery suggestion.
    var recoverySuggestion: String? {
        switch self {
        case .modelNotInstalled:
            return "Open Settings and download the model."
        case .modelInitializationFailed:
            return "Try restarting the app or selecting a different model."
        case .audioFileNotFound:
            return "The recording may have been deleted."
        case .invalidAudioFormat:
            return "Please try recording again."
        case .transcriptionCancelled:
            return nil
        case .transcriptionFailed:
            return "Try recording again or select a different model."
        case .insufficientMemory:
            return "Close other applications or select a smaller model."
        }
    }
}

// MARK: - ModelRunner

/// Loads and runs the Whisper model for speech-to-text transcription.
///
/// ## Threading Model
/// - Model initialization runs on a background Task to avoid blocking the UI.
/// - Transcription runs on the calling Task (expected to be a background Task).
/// - Results are safe to use from any context (value types).
/// - Use `@MainActor` when updating UI state with results.
///
/// ## Cancellation
/// Transcription supports cooperative cancellation via Swift's Task cancellation.
/// When a new transcription starts, any in-progress transcription is automatically
/// cancelled.
///
/// ## Memory Management
/// - Models are loaded lazily on first transcribe call.
/// - Models remain loaded for fast subsequent transcriptions.
/// - Call `unloadModel()` to free memory when not in use.
/// - The system may reclaim memory under pressure; model will reload on next use.
///
/// ## Model Storage
/// WhisperKit manages model storage at its default location.
/// Models are downloaded from HuggingFace on first use.
actor ModelRunner {

    // MARK: - Properties

    /// The currently loaded WhisperKit pipeline, if any.
    private var whisperKit: WhisperKit?

    /// The model variant currently loaded.
    private var loadedModel: WhisperModel?

    /// Current transcription task, for cancellation support.
    private var currentTranscriptionTask: Task<String, Error>?

    /// Flag to signal cancellation to the progress callback.
    private var shouldCancelTranscription = false

    /// Whether a model is currently loading.
    private(set) var isLoading = false

    // MARK: - Initialization

    init() {
        Logger.model.debug("ModelRunner initialized")
    }

    // MARK: - Public API

    /// Transcribes audio from the given URL using the specified model.
    ///
    /// If a different model is requested than currently loaded, the new model
    /// will be loaded first. If a transcription is already in progress, it will
    /// be cancelled before starting the new one.
    ///
    /// - Parameters:
    ///   - audioURL: URL to the audio file (WAV, M4A, MP3, FLAC supported).
    ///   - model: The Whisper model variant to use.
    /// - Returns: The transcribed text.
    /// - Throws: `ModelRunnerError` if transcription fails.
    func transcribe(audioURL: URL, model: WhisperModel) async throws -> String {
        let startTime = CFAbsoluteTimeGetCurrent()
        let modelName = model.displayName

        Logger.model.info("Starting transcription with model: \(modelName)")

        // Cancel any in-progress transcription
        await cancelCurrentTranscription()

        // Validate audio file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            Logger.model.error("Audio file not found: \(audioURL.path)")
            throw ModelRunnerError.audioFileNotFound(audioURL)
        }

        // Load model if needed
        try await ensureModelLoaded(model)

        guard let pipe = whisperKit else {
            throw ModelRunnerError.modelInitializationFailed(
                underlying: "Pipeline not available after loading"
            )
        }

        // Reset cancellation flag
        shouldCancelTranscription = false

        // Create transcription task
        let transcriptionTask = Task<String, Error> { [pipe, modelName] in
            do {
                // Check cancellation before starting
                try Task.checkCancellation()

                // Transcribe the audio file
                let results = try await pipe.transcribe(audioPath: audioURL.path)

                // Check cancellation after completion
                try Task.checkCancellation()

                // Extract text from results
                let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

                // Log benchmark
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                Logger.model.info("Transcription complete: model=\(modelName), latency=\(String(format: "%.2f", elapsed))s, chars=\(text.count)")

                return text

            } catch is CancellationError {
                Logger.model.info("Transcription cancelled")
                throw ModelRunnerError.transcriptionCancelled
            } catch {
                Logger.model.error("Transcription failed: \(error)")
                throw ModelRunnerError.transcriptionFailed(underlying: error.localizedDescription)
            }
        }

        currentTranscriptionTask = transcriptionTask

        return try await transcriptionTask.value
    }

    /// Cancels any in-progress transcription.
    func cancelCurrentTranscription() async {
        guard let task = currentTranscriptionTask else { return }

        Logger.model.info("Cancelling current transcription")
        shouldCancelTranscription = true
        task.cancel()
        currentTranscriptionTask = nil

        // Small delay to allow cancellation to propagate
        try? await Task.sleep(for: .milliseconds(50))
    }

    /// Preloads the specified model without transcribing.
    ///
    /// Call this to warm up the model before the user starts recording,
    /// reducing latency on first transcription.
    ///
    /// - Parameter model: The model to preload.
    func preloadModel(_ model: WhisperModel) async throws {
        try await ensureModelLoaded(model)
    }

    /// Unloads the current model to free memory.
    func unloadModel() async {
        guard whisperKit != nil else { return }

        let modelName = self.loadedModel?.displayName ?? "unknown"
        Logger.model.info("Unloading model: \(modelName)")

        whisperKit = nil
        loadedModel = nil
    }

    /// Returns the currently loaded model, if any.
    func currentlyLoadedModel() -> WhisperModel? {
        loadedModel
    }

    // MARK: - Private Methods

    /// Ensures the specified model is loaded, loading it if necessary.
    private func ensureModelLoaded(_ model: WhisperModel) async throws {
        let modelName = model.displayName

        // If the correct model is already loaded, we're done
        if loadedModel == model && whisperKit != nil {
            Logger.model.debug("Model already loaded: \(modelName)")
            return
        }

        // Unload current model if different
        if loadedModel != nil && loadedModel != model {
            await unloadModel()
        }

        isLoading = true
        defer { isLoading = false }

        Logger.model.info("Loading model: \(modelName)")
        let loadStart = CFAbsoluteTimeGetCurrent()

        do {
            let pipe = try await WhisperKit(
                model: model.whisperKitModelName,
                verbose: false,
                logLevel: .error,
                prewarm: true,
                download: true
            )

            whisperKit = pipe
            loadedModel = model

            let loadTime = CFAbsoluteTimeGetCurrent() - loadStart
            Logger.model.info("Model loaded: \(modelName) in \(String(format: "%.2f", loadTime))s")

        } catch {
            Logger.model.error("Failed to load model \(modelName): \(error)")
            throw ModelRunnerError.modelInitializationFailed(underlying: error.localizedDescription)
        }
    }
}
