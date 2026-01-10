import AudioToolbox
import CoreAudio
import Foundation
import os

// MARK: - AudioDevice

/// Represents an audio input device.
struct AudioDevice: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let isDefault: Bool
}

// MARK: - AudioDeviceManager

/// Service for enumerating and monitoring audio input devices.
///
/// Threading: This class is `@Observable` and `@MainActor` for UI binding.
/// Device enumeration uses CoreAudio synchronous APIs.
@Observable
@MainActor
final class AudioDeviceManager {
    /// Available audio input devices.
    private(set) var inputDevices: [AudioDevice] = []

    /// The default input device ID, if available.
    private(set) var defaultInputDeviceID: String?

    /// Property listener for device changes.
    private var propertyListenerBlock: AudioObjectPropertyListenerBlock?

    init() {
        refreshDevices()
    }

    deinit {
        // Note: Can't call stopMonitoring() here since we're @MainActor
        // The property listener will be cleaned up when the process exits
    }

    // MARK: - Public Methods

    /// Refreshes the list of available input devices.
    func refreshDevices() {
        inputDevices = enumerateInputDevices()
        defaultInputDeviceID = getDefaultInputDeviceID()
        Logger.audio.debug("Found \(self.inputDevices.count) input devices")
    }

    /// Starts monitoring for device changes.
    func startMonitoring() {
        guard propertyListenerBlock == nil else { return }

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        // Capture self weakly to avoid retain cycle
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.refreshDevices()
            }
        }

        propertyListenerBlock = block

        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )

        if status != noErr {
            Logger.audio.warning("Failed to add device change listener: \(status)")
        } else {
            Logger.audio.debug("Started monitoring audio device changes")
        }
    }

    /// Stops monitoring for device changes.
    func stopMonitoring() {
        guard let block = propertyListenerBlock else { return }

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            block
        )

        propertyListenerBlock = nil
        Logger.audio.debug("Stopped monitoring audio device changes")
    }

    // MARK: - Private Methods

    /// Enumerates all audio input devices.
    private func enumerateInputDevices() -> [AudioDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        guard status == noErr else {
            Logger.audio.error("Failed to get device list size: \(status)")
            return []
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )

        guard status == noErr else {
            Logger.audio.error("Failed to get device list: \(status)")
            return []
        }

        let defaultID = getDefaultInputDeviceID()

        return deviceIDs.compactMap { deviceID -> AudioDevice? in
            // Check if device has input streams
            guard hasInputStreams(deviceID: deviceID) else { return nil }

            // Get device name
            guard let name = getDeviceName(deviceID: deviceID) else { return nil }

            let uid = getDeviceUID(deviceID: deviceID) ?? String(deviceID)
            let isDefault = uid == defaultID

            return AudioDevice(id: uid, name: name, isDefault: isDefault)
        }
    }

    /// Checks if a device has input streams.
    private func hasInputStreams(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        return status == noErr && dataSize > 0
    }

    /// Gets the name of a device.
    private func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &name
        )

        guard status == noErr, let deviceName = name else { return nil }
        return deviceName as String
    }

    /// Gets the unique identifier of a device.
    private func getDeviceUID(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &uid
        )

        guard status == noErr, let deviceUID = uid else { return nil }
        return deviceUID as String
    }

    /// Gets the default input device ID.
    private func getDefaultInputDeviceID() -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )

        guard status == noErr, deviceID != 0 else { return nil }
        return getDeviceUID(deviceID: deviceID)
    }
}
