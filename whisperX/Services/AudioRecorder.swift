import AVFoundation
import Foundation
import os

// MARK: - AudioRecorderError

/// Errors that can occur during audio recording.
enum AudioRecorderError: Error, LocalizedError {
    case microphonePermissionDenied
    case engineSetupFailed(Error)
    case recordingInProgress
    case noRecordingInProgress
    case fileCreationFailed
    case inputNodeUnavailable

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission is required for recording."
        case .engineSetupFailed(let error):
            return "Audio engine setup failed: \(error.localizedDescription)"
        case .recordingInProgress:
            return "A recording is already in progress."
        case .noRecordingInProgress:
            return "No recording is currently in progress."
        case .fileCreationFailed:
            return "Failed to create the recording file."
        case .inputNodeUnavailable:
            return "Audio input device is not available."
        }
    }
}

// MARK: - AudioRecorder

/// Records audio from the microphone to a temporary WAV file.
///
/// Uses AVAudioEngine for low-latency audio capture. Records mono 16kHz PCM audio,
/// which is the native format expected by Whisper models. Using 16kHz directly
/// avoids resampling overhead and potential quality loss.
///
/// Threading: Setup and teardown run on the calling thread (expected to be main).
/// Audio buffer processing runs on AVAudioEngine's internal audio queue.
///
/// Requires: Microphone permission (NSMicrophoneUsageDescription in Info.plist).
final class AudioRecorder {
    // MARK: - Configuration

    /// Sample rate for recording.
    /// Whisper models natively expect 16kHz audio. Recording at this rate
    /// avoids resampling and preserves audio quality.
    static let sampleRate: Double = 16000

    /// Number of audio channels (mono).
    /// Whisper models expect mono audio; stereo would require downmixing.
    static let channels: AVAudioChannelCount = 1

    // MARK: - State

    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var currentRecordingURL: URL?

    /// Thread-safe flag indicating if recording is in progress.
    private var _isRecording = false
    private let recordingLock = NSLock()

    /// Whether a recording is currently in progress.
    var isRecording: Bool {
        recordingLock.lock()
        defer { recordingLock.unlock() }
        return _isRecording
    }

    // MARK: - Public Methods

    /// Starts recording audio to a temporary file.
    ///
    /// - Returns: URL of the recording file (file will be complete after stopRecording).
    /// - Throws: `AudioRecorderError` if setup fails or recording already in progress.
    func startRecording() throws -> URL {
        recordingLock.lock()
        defer { recordingLock.unlock() }

        guard !_isRecording else {
            Logger.audio.warning("Attempted to start recording while already recording")
            throw AudioRecorderError.recordingInProgress
        }

        // Create temp file URL
        let url = createTempFileURL()
        Logger.audio.info("Starting recording to: \(url.path)")

        // Get input node
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.channelCount > 0 else {
            Logger.audio.error("No audio input available")
            throw AudioRecorderError.inputNodeUnavailable
        }

        // Create our target recording format (16kHz mono)
        guard let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.sampleRate,
            channels: Self.channels,
            interleaved: false
        ) else {
            Logger.audio.error("Failed to create recording format")
            throw AudioRecorderError.fileCreationFailed
        }

        // Create the audio file
        do {
            audioFile = try AVAudioFile(
                forWriting: url,
                settings: recordingFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
        } catch {
            Logger.audio.error("Failed to create audio file: \(error)")
            throw AudioRecorderError.fileCreationFailed
        }

        // Install tap on input node with format conversion if needed
        // AVAudioEngine handles sample rate conversion automatically when formats differ
        let bufferSize: AVAudioFrameCount = 4096

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, inputFormat: inputFormat, targetFormat: recordingFormat)
        }

        // Start the engine
        do {
            try audioEngine.start()
            Logger.audio.debug("Audio engine started")
        } catch {
            inputNode.removeTap(onBus: 0)
            audioFile = nil
            Logger.audio.error("Failed to start audio engine: \(error)")
            throw AudioRecorderError.engineSetupFailed(error)
        }

        currentRecordingURL = url
        _isRecording = true

        Logger.audio.info("Recording started successfully")
        return url
    }

    /// Stops the current recording.
    ///
    /// - Returns: URL of the completed recording file.
    /// - Throws: `AudioRecorderError` if no recording is in progress.
    func stopRecording() throws -> URL {
        recordingLock.lock()
        defer { recordingLock.unlock() }

        guard _isRecording else {
            Logger.audio.warning("Attempted to stop recording when not recording")
            throw AudioRecorderError.noRecordingInProgress
        }

        guard let url = currentRecordingURL else {
            throw AudioRecorderError.noRecordingInProgress
        }

        // Stop the engine and remove tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // Close the file
        audioFile = nil

        _isRecording = false
        currentRecordingURL = nil

        // Log file info
        logRecordingInfo(url)

        Logger.audio.info("Recording stopped: \(url.path)")
        return url
    }

    // MARK: - Private Methods

    /// Creates a unique temporary file URL for the recording.
    private func createTempFileURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "whisperx_recording_\(UUID().uuidString).wav"
        return tempDir.appendingPathComponent(filename)
    }

    /// Processes an audio buffer and writes it to the file.
    /// Handles format conversion from input format to 16kHz mono.
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat, targetFormat: AVAudioFormat) {
        guard let audioFile = audioFile else { return }

        // If formats match, write directly
        if inputFormat.sampleRate == targetFormat.sampleRate &&
           inputFormat.channelCount == targetFormat.channelCount {
            do {
                try audioFile.write(from: buffer)
            } catch {
                Logger.audio.error("Failed to write audio buffer: \(error)")
            }
            return
        }

        // Need to convert: create converter and converted buffer
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            Logger.audio.error("Failed to create audio converter")
            return
        }

        // Calculate output frame count based on sample rate ratio
        let ratio = targetFormat.sampleRate / inputFormat.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
            Logger.audio.error("Failed to create conversion buffer")
            return
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            Logger.audio.error("Audio conversion failed: \(error)")
            return
        }

        do {
            try audioFile.write(from: convertedBuffer)
        } catch {
            Logger.audio.error("Failed to write converted audio buffer: \(error)")
        }
    }

    /// Logs information about the completed recording.
    private func logRecordingInfo(_ url: URL) {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attrs[.size] as? Int64 {
                let sizeKB = Double(size) / 1024.0
                Logger.audio.info("Recording file size: \(String(format: "%.1f", sizeKB)) KB")
            }
        } catch {
            Logger.audio.debug("Could not read recording file attributes: \(error)")
        }
    }
}
