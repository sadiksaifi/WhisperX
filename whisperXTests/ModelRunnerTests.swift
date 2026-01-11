//
//  ModelRunnerTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class ModelRunnerTests: XCTestCase {

    // MARK: - ModelRunnerError Descriptions

    func testModelNotInstalledDescription() {
        let error = ModelRunnerError.modelNotInstalled(.large)
        XCTAssertEqual(
            error.errorDescription,
            "Model 'Large v3' is not installed. Please download it in Settings."
        )
    }

    func testModelNotInstalledDescriptionForTiny() {
        let error = ModelRunnerError.modelNotInstalled(.tiny)
        XCTAssertEqual(
            error.errorDescription,
            "Model 'Tiny' is not installed. Please download it in Settings."
        )
    }

    func testModelInitializationFailedDescription() {
        let error = ModelRunnerError.modelInitializationFailed(underlying: "Memory allocation failed")
        XCTAssertEqual(
            error.errorDescription,
            "Failed to initialize model: Memory allocation failed"
        )
    }

    func testAudioFileNotFoundDescription() {
        let url = URL(fileURLWithPath: "/path/to/recording.wav")
        let error = ModelRunnerError.audioFileNotFound(url)
        XCTAssertEqual(
            error.errorDescription,
            "Audio file not found: recording.wav"
        )
    }

    func testInvalidAudioFormatDescription() {
        let error = ModelRunnerError.invalidAudioFormat("Unsupported codec")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid audio format: Unsupported codec"
        )
    }

    func testTranscriptionCancelledDescription() {
        let error = ModelRunnerError.transcriptionCancelled
        XCTAssertEqual(
            error.errorDescription,
            "Transcription was cancelled."
        )
    }

    func testTranscriptionFailedDescription() {
        let error = ModelRunnerError.transcriptionFailed(underlying: "Processing timeout")
        XCTAssertEqual(
            error.errorDescription,
            "Transcription failed: Processing timeout"
        )
    }

    func testInsufficientMemoryDescription() {
        let error = ModelRunnerError.insufficientMemory(required: 6.0, available: 4.5)
        XCTAssertEqual(
            error.errorDescription,
            "Insufficient memory. Required: 6.0 GB, Available: 4.5 GB"
        )
    }

    // MARK: - ModelRunnerError Recovery Suggestions

    func testModelNotInstalledRecoverySuggestion() {
        let error = ModelRunnerError.modelNotInstalled(.base)
        XCTAssertEqual(
            error.recoverySuggestion,
            "Open Settings and download the model."
        )
    }

    func testModelInitializationFailedRecoverySuggestion() {
        let error = ModelRunnerError.modelInitializationFailed(underlying: "test")
        XCTAssertEqual(
            error.recoverySuggestion,
            "Try restarting the app or selecting a different model."
        )
    }

    func testAudioFileNotFoundRecoverySuggestion() {
        let url = URL(fileURLWithPath: "/test.wav")
        let error = ModelRunnerError.audioFileNotFound(url)
        XCTAssertEqual(
            error.recoverySuggestion,
            "The recording may have been deleted."
        )
    }

    func testInvalidAudioFormatRecoverySuggestion() {
        let error = ModelRunnerError.invalidAudioFormat("test")
        XCTAssertEqual(
            error.recoverySuggestion,
            "Please try recording again."
        )
    }

    func testTranscriptionCancelledRecoverySuggestion() {
        let error = ModelRunnerError.transcriptionCancelled
        XCTAssertNil(error.recoverySuggestion)
    }

    func testTranscriptionFailedRecoverySuggestion() {
        let error = ModelRunnerError.transcriptionFailed(underlying: "test")
        XCTAssertEqual(
            error.recoverySuggestion,
            "Try recording again or select a different model."
        )
    }

    func testInsufficientMemoryRecoverySuggestion() {
        let error = ModelRunnerError.insufficientMemory(required: 6.0, available: 4.0)
        XCTAssertEqual(
            error.recoverySuggestion,
            "Close other applications or select a smaller model."
        )
    }

    // MARK: - ModelRunnerError Conformance

    func testModelRunnerErrorIsError() {
        let error: Error = ModelRunnerError.transcriptionCancelled
        XCTAssertTrue(error is ModelRunnerError)
    }

    func testModelRunnerErrorIsLocalizedError() {
        let error: LocalizedError = ModelRunnerError.transcriptionCancelled
        XCTAssertNotNil(error.errorDescription)
    }

    func testModelRunnerErrorIsSendable() async {
        let error = ModelRunnerError.transcriptionCancelled
        let task = Task { @Sendable in
            return error.errorDescription
        }
        let result = await task.value
        XCTAssertEqual(result, "Transcription was cancelled.")
    }

    // MARK: - All Error Cases

    func testAllErrorCasesHaveDescriptions() {
        let url = URL(fileURLWithPath: "/test.wav")

        let errors: [ModelRunnerError] = [
            .modelNotInstalled(.tiny),
            .modelInitializationFailed(underlying: "test"),
            .audioFileNotFound(url),
            .invalidAudioFormat("test"),
            .transcriptionCancelled,
            .transcriptionFailed(underlying: "test"),
            .insufficientMemory(required: 1.0, available: 0.5)
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Missing description for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Empty description for \(error)")
        }
    }

    func testAllErrorCasesHaveRecoverySuggestionsExceptCancelled() {
        let url = URL(fileURLWithPath: "/test.wav")

        let errorsWithSuggestions: [ModelRunnerError] = [
            .modelNotInstalled(.tiny),
            .modelInitializationFailed(underlying: "test"),
            .audioFileNotFound(url),
            .invalidAudioFormat("test"),
            .transcriptionFailed(underlying: "test"),
            .insufficientMemory(required: 1.0, available: 0.5)
        ]

        for error in errorsWithSuggestions {
            XCTAssertNotNil(error.recoverySuggestion, "Missing recovery suggestion for \(error)")
        }

        // Cancelled should not have a recovery suggestion
        XCTAssertNil(ModelRunnerError.transcriptionCancelled.recoverySuggestion)
    }
}
