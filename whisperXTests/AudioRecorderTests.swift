//
//  AudioRecorderTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class AudioRecorderTests: XCTestCase {

    // MARK: - AudioRecorderError Descriptions

    func testMicrophonePermissionDeniedDescription() {
        let error = AudioRecorderError.microphonePermissionDenied
        XCTAssertEqual(
            error.errorDescription,
            "Microphone permission is required for recording."
        )
    }

    func testEngineSetupFailedDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "Engine configuration error"
        ])
        let error = AudioRecorderError.engineSetupFailed(underlyingError)
        XCTAssertEqual(
            error.errorDescription,
            "Audio engine setup failed: Engine configuration error"
        )
    }

    func testRecordingInProgressDescription() {
        let error = AudioRecorderError.recordingInProgress
        XCTAssertEqual(
            error.errorDescription,
            "A recording is already in progress."
        )
    }

    func testNoRecordingInProgressDescription() {
        let error = AudioRecorderError.noRecordingInProgress
        XCTAssertEqual(
            error.errorDescription,
            "No recording is currently in progress."
        )
    }

    func testFileCreationFailedDescription() {
        let error = AudioRecorderError.fileCreationFailed
        XCTAssertEqual(
            error.errorDescription,
            "Failed to create the recording file."
        )
    }

    func testInputNodeUnavailableDescription() {
        let error = AudioRecorderError.inputNodeUnavailable
        XCTAssertEqual(
            error.errorDescription,
            "Audio input device is not available."
        )
    }

    // MARK: - AudioRecorder Configuration

    func testSampleRateConfiguration() {
        XCTAssertEqual(AudioRecorder.sampleRate, 16000)
    }

    func testChannelsConfiguration() {
        XCTAssertEqual(AudioRecorder.channels, 1)
    }

    // MARK: - AudioRecorderError Conformance

    func testAudioRecorderErrorIsError() {
        let error: Error = AudioRecorderError.microphonePermissionDenied
        XCTAssertTrue(error is AudioRecorderError)
    }

    func testAudioRecorderErrorIsLocalizedError() {
        let error: LocalizedError = AudioRecorderError.microphonePermissionDenied
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - AudioRecorder Initial State

    func testAudioRecorderInitialIsRecordingState() {
        let recorder = AudioRecorder()
        XCTAssertFalse(recorder.isRecording)
    }

    // MARK: - Error Cases

    func testAllErrorCasesHaveDescriptions() {
        let underlyingError = NSError(domain: "Test", code: 0, userInfo: nil)

        let errors: [AudioRecorderError] = [
            .microphonePermissionDenied,
            .engineSetupFailed(underlyingError),
            .recordingInProgress,
            .noRecordingInProgress,
            .fileCreationFailed,
            .inputNodeUnavailable
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Missing description for \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Empty description for \(error)")
        }
    }
}
