import Foundation

/// Represents the app's installation location status.
enum InstallationLocation: Equatable {
    /// App is installed in /Applications (ideal)
    case applications
    /// App is installed in ~/Applications (acceptable)
    case userApplications
    /// App is running from Downloads folder
    case downloads
    /// App is running from a mounted DMG (read-only)
    case dmg
    /// App is running from some other location
    case other(path: String)

    /// Whether the app is properly installed.
    var isInstalled: Bool {
        switch self {
        case .applications, .userApplications:
            return true
        default:
            return false
        }
    }

    /// Whether the app is in a read-only location (cannot auto-move).
    var isReadOnly: Bool {
        self == .dmg
    }

    /// Detects the current installation location of the app bundle.
    static func detect() -> InstallationLocation {
        let bundlePath = Bundle.main.bundlePath

        // Check if in /Applications
        if bundlePath.hasPrefix("/Applications/") {
            return .applications
        }

        // Check if in ~/Applications
        let userApps = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications").path
        if bundlePath.hasPrefix(userApps) {
            return .userApplications
        }

        // Check if in Downloads folder
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            if bundlePath.hasPrefix(downloads.path) {
                return .downloads
            }
        }

        // Check if running from DMG (mounted volume)
        if bundlePath.hasPrefix("/Volumes/") {
            return .dmg
        }

        return .other(path: bundlePath)
    }
}

/// Result of the installation wizard interaction.
enum InstallationResult {
    /// Successfully moved, app will relaunch
    case moved
    /// User clicked "Later", don't show again this session
    case later
    /// User wants to keep running from current location
    case runFromCurrent
}
