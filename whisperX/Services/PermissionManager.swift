import AppKit
import AVFoundation
import os

// MARK: - PermissionType

/// Types of system permissions required by the app.
enum PermissionType {
    case accessibility
    case microphone
}

// MARK: - PermissionStatus

/// Status of a system permission.
enum PermissionStatus: Equatable {
    case unknown
    case granted
    case denied
    case notDetermined
}

// MARK: - PermissionManager

/// Centralized manager for system permission checking and user guidance.
///
/// Handles Accessibility (Input Monitoring) and Microphone permissions:
/// - Checks current permission status
/// - Provides pre-flight guidance before triggering system prompts
/// - Opens System Settings to the appropriate pane
///
/// Threading: All methods run on MainActor for UI safety.
@Observable
@MainActor
final class PermissionManager {
    // MARK: - Published State

    private(set) var accessibilityStatus: PermissionStatus = .unknown
    private(set) var microphoneStatus: PermissionStatus = .unknown

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let hasShownAccessibilityGuidance = "hasShownAccessibilityGuidance"
        static let hasShownMicrophoneGuidance = "hasShownMicrophoneGuidance"
    }

    // MARK: - Initialization

    init() {
        refreshAccessibilityStatus()
        refreshMicrophoneStatus()
    }

    // MARK: - Accessibility Permission

    /// Checks if Accessibility (Input Monitoring) permission is granted.
    /// Uses AXIsProcessTrusted() from ApplicationServices.
    func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        accessibilityStatus = trusted ? .granted : .denied
        Logger.app.debug("Accessibility permission: \(trusted)")
        return trusted
    }

    /// Refreshes the accessibility status without returning a value.
    func refreshAccessibilityStatus() {
        _ = checkAccessibilityPermission()
    }

    /// Opens System Settings to the Accessibility > Input Monitoring pane.
    /// Also triggers the system prompt to add the app to the trusted list.
    func openAccessibilitySettings() {
        // Trigger the system prompt by calling AXIsProcessTrustedWithOptions with prompt option
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        Logger.app.info("Triggered Accessibility permission prompt")
    }

    // MARK: - Microphone Permission

    /// Checks the current microphone permission status.
    func checkMicrophonePermission() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        let permStatus = mapAVAuthStatus(status)
        microphoneStatus = permStatus
        Logger.audio.debug("Microphone permission: \(String(describing: permStatus))")
        return permStatus
    }

    /// Refreshes the microphone status without returning a value.
    func refreshMicrophoneStatus() {
        _ = checkMicrophonePermission()
    }

    /// Requests microphone permission from the system.
    /// Returns true if granted, false otherwise.
    func requestMicrophonePermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = granted ? .granted : .denied
        Logger.audio.info("Microphone permission request result: \(granted)")
        return granted
    }

    /// Opens System Settings to the Microphone privacy pane.
    func openMicrophoneSettings() {
        // Try the newer macOS 13+ URL format first, fall back to legacy
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone"
        ]

        for urlString in urls {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                Logger.app.info("Opened Microphone settings")
                return
            }
        }
    }

    // MARK: - Guidance Dialog Tracking

    /// Returns true if the accessibility guidance dialog should be shown (first time only).
    /// Marks the dialog as shown after returning true.
    func shouldShowAccessibilityGuidance() -> Bool {
        let hasShown = UserDefaults.standard.bool(forKey: Keys.hasShownAccessibilityGuidance)
        if !hasShown {
            UserDefaults.standard.set(true, forKey: Keys.hasShownAccessibilityGuidance)
            return true
        }
        return false
    }

    /// Returns true if the microphone guidance dialog should be shown (first time only).
    /// Marks the dialog as shown after returning true.
    func shouldShowMicrophoneGuidance() -> Bool {
        let hasShown = UserDefaults.standard.bool(forKey: Keys.hasShownMicrophoneGuidance)
        if !hasShown {
            UserDefaults.standard.set(true, forKey: Keys.hasShownMicrophoneGuidance)
            return true
        }
        return false
    }

    /// Resets guidance flags (for testing purposes).
    func resetGuidanceFlags() {
        UserDefaults.standard.removeObject(forKey: Keys.hasShownAccessibilityGuidance)
        UserDefaults.standard.removeObject(forKey: Keys.hasShownMicrophoneGuidance)
    }

    // MARK: - Private Helpers

    private func mapAVAuthStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .unknown
        }
    }
}
