import AppKit
import os

/// Handles app bundle relocation and relaunch operations.
@MainActor
final class InstallationService {
    private static let logger = Logger(subsystem: "com.whisperx", category: "installation")

    /// The destination path in /Applications.
    static var applicationsFolderURL: URL {
        URL(fileURLWithPath: "/Applications")
            .appendingPathComponent(Bundle.main.bundleURL.lastPathComponent)
    }

    /// Checks if the app needs to show the installation wizard.
    static func needsInstallation() -> Bool {
        let location = InstallationLocation.detect()
        return !location.isInstalled
    }

    /// Checks if /Applications is writable without elevated privileges.
    static func canWriteToApplications() -> Bool {
        FileManager.default.isWritableFile(atPath: "/Applications")
    }

    /// Moves the app to /Applications.
    /// Returns the path to the new bundle on success.
    static func moveToApplications() async throws -> URL {
        let source = Bundle.main.bundleURL
        let destination = applicationsFolderURL

        logger.info("Moving app from \(source.path) to \(destination.path)")

        // Remove existing app if present
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        // Copy to Applications (copy first, then delete source after success)
        try FileManager.default.copyItem(at: source, to: destination)

        // Verify the copy
        guard FileManager.default.fileExists(atPath: destination.path) else {
            throw InstallationError.copyFailed
        }

        logger.info("App moved successfully to \(destination.path)")
        return destination
    }

    /// Moves the app using AppleScript authorization for privilege escalation.
    static func moveToApplicationsWithPrivileges() async throws -> URL {
        let source = Bundle.main.bundleURL
        let destination = applicationsFolderURL

        logger.info("Moving app with privileges from \(source.path) to \(destination.path)")

        // Use AppleScript for privilege escalation
        let script = """
        do shell script "rm -rf '\(destination.path)' && cp -R '\(source.path)' '\(destination.path)'" with administrator privileges
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                throw InstallationError.privilegeEscalationFailed(message: message)
            }
        } else {
            throw InstallationError.privilegeEscalationFailed(message: "Failed to create script")
        }

        // Verify the copy
        guard FileManager.default.fileExists(atPath: destination.path) else {
            throw InstallationError.copyFailed
        }

        logger.info("App moved successfully with privileges to \(destination.path)")
        return destination
    }

    /// Deletes the original app bundle after successful move.
    static func deleteOriginalBundle() {
        let source = Bundle.main.bundleURL

        // Only delete if not in Applications (safety check)
        guard !source.path.hasPrefix("/Applications/") else {
            logger.warning("Refusing to delete app from /Applications")
            return
        }

        do {
            try FileManager.default.removeItem(at: source)
            logger.info("Deleted original bundle at \(source.path)")
        } catch {
            // Non-fatal - user can delete manually
            logger.warning("Could not delete original bundle: \(error.localizedDescription)")
        }
    }

    /// Relaunches the app from the new location.
    static func relaunch(from bundleURL: URL) {
        logger.info("Relaunching from \(bundleURL.path)")

        // Use NSWorkspace to open the new app
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(
            at: bundleURL,
            configuration: configuration
        ) { _, error in
            if error == nil {
                // Terminate current instance
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            } else {
                Self.logger.error("Failed to relaunch: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }

    /// Opens Finder at the Downloads folder.
    static func openDownloadsFolder() {
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.open(downloads)
        }
    }

    /// Opens Finder at the /Applications folder.
    static func openApplicationsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
    }

    /// Opens Finder showing the current app bundle selected.
    static func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
}

/// Errors that can occur during installation.
enum InstallationError: Error, LocalizedError {
    case copyFailed
    case privilegeEscalationFailed(message: String)
    case readOnlySource
    case alreadyInstalled

    var errorDescription: String? {
        switch self {
        case .copyFailed:
            return "Failed to copy app to Applications folder"
        case .privilegeEscalationFailed(let message):
            return "Permission denied: \(message)"
        case .readOnlySource:
            return "Cannot move app from read-only location. Please drag to Applications manually."
        case .alreadyInstalled:
            return "App is already installed"
        }
    }
}
