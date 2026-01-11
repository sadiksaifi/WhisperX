//
//  UpdateState.swift
//  whisperX
//

import Foundation

// MARK: - GitHub API Models

/// Represents a GitHub release from the releases API.
struct GitHubRelease: Codable, Sendable {
    let tagName: String
    let name: String
    let body: String
    let htmlUrl: String
    let publishedAt: String
    let prerelease: Bool
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case prerelease
        case assets
    }

    /// Determines the release channel based on tag name parsing.
    var channel: ReleaseChannel {
        guard let version = SemanticVersion(string: tagName) else {
            return prerelease ? .beta : .stable
        }
        return version.channel
    }
}

/// Represents a downloadable asset attached to a GitHub release.
struct GitHubAsset: Codable, Sendable {
    let name: String
    let browserDownloadUrl: String
    let size: Int
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
        case contentType = "content_type"
    }
}

// MARK: - Update State

/// Current state of the update check/download process.
enum UpdateCheckState: Equatable, Sendable {
    case idle
    case checking
    case available(version: String, release: GitHubRelease)
    /// User is on a pre-release but a newer stable version exists.
    case stableNewer(stableVersion: String, stableRelease: GitHubRelease, currentVersion: String)
    case downloading(progress: Double)
    case readyToInstall
    case installing
    case error(message: String)
    case upToDate

    static func == (lhs: UpdateCheckState, rhs: UpdateCheckState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.checking, .checking),
             (.readyToInstall, .readyToInstall),
             (.installing, .installing),
             (.upToDate, .upToDate):
            return true
        case let (.available(v1, _), .available(v2, _)):
            return v1 == v2
        case let (.stableNewer(v1, _, c1), .stableNewer(v2, _, c2)):
            return v1 == v2 && c1 == c2
        case let (.downloading(p1), .downloading(p2)):
            return p1 == p2
        case let (.error(m1), .error(m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

// MARK: - Release Channel

/// Represents the update channel for receiving different release types.
enum ReleaseChannel: String, Codable, CaseIterable, Sendable {
    case stable
    case beta
    case alpha

    var displayName: String {
        switch self {
        case .stable: return "Stable"
        case .beta: return "Beta"
        case .alpha: return "Alpha"
        }
    }

    var description: String {
        switch self {
        case .stable: return "Recommended for most users"
        case .beta: return "Preview features, may have bugs"
        case .alpha: return "Experimental, expect issues"
        }
    }
}

// MARK: - Pre-Release Type

/// Represents the pre-release component of a semantic version.
enum PreReleaseType: Sendable, CustomStringConvertible {
    case dev(Int)   // local development build
    case alpha(Int)
    case beta(Int)
    case none  // stable release

    var description: String {
        switch self {
        case .dev(let n): return "dev.\(n)"
        case .alpha(let n): return "alpha.\(n)"
        case .beta(let n): return "beta.\(n)"
        case .none: return ""
        }
    }

    var channel: ReleaseChannel {
        switch self {
        case .dev: return .alpha  // dev builds use alpha channel for updates
        case .alpha: return .alpha
        case .beta: return .beta
        case .none: return .stable
        }
    }

    /// Returns true if this is a development build (not distributed via releases).
    var isDev: Bool {
        if case .dev = self { return true }
        return false
    }

    /// Parse pre-release string like "alpha.1", "beta.2", or "dev.3"
    static func parse(_ string: String) -> PreReleaseType {
        let parts = string.lowercased().split(separator: ".")
        guard parts.count >= 2,
              let number = Int(parts[1]) else {
            // Check for just "alpha", "beta", or "dev" without number
            if string.lowercased().hasPrefix("dev") {
                return .dev(1)
            } else if string.lowercased().hasPrefix("alpha") {
                return .alpha(1)
            } else if string.lowercased().hasPrefix("beta") {
                return .beta(1)
            }
            return .none
        }

        if parts[0] == "dev" {
            return .dev(number)
        } else if parts[0] == "alpha" {
            return .alpha(number)
        } else if parts[0] == "beta" {
            return .beta(number)
        }
        return .none
    }
}

extension PreReleaseType: Comparable {
    static func < (lhs: PreReleaseType, rhs: PreReleaseType) -> Bool {
        switch (lhs, rhs) {
        case (.dev(let a), .dev(let b)):
            return a < b
        case (.alpha(let a), .alpha(let b)):
            return a < b
        case (.beta(let a), .beta(let b)):
            return a < b
        // Ordering: dev < alpha < beta < stable
        case (.dev, .alpha), (.dev, .beta), (.dev, .none),
             (.alpha, .beta), (.alpha, .none),
             (.beta, .none):
            return true
        case (.none, _), (.beta, .alpha), (.beta, .dev),
             (.alpha, .dev):
            return false
        }
    }
}

// MARK: - Semantic Version

/// Parsed semantic version for comparison, supporting pre-release suffixes.
struct SemanticVersion: Comparable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    let preRelease: PreReleaseType

    var description: String {
        let base = "\(major).\(minor).\(patch)"
        if case .none = preRelease {
            return base
        }
        return "\(base)-\(preRelease)"
    }

    /// The release channel this version belongs to.
    var channel: ReleaseChannel {
        preRelease.channel
    }

    /// Initializes from a version string like "1.0.0", "v1.0.0", "1.0.0-beta.1", or "1.0.0-alpha.2".
    init?(string: String) {
        let cleaned = string.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

        // Split on hyphen to separate version from pre-release
        let mainParts = cleaned.split(separator: "-", maxSplits: 1)
        let versionString = String(mainParts[0])

        // Parse major.minor.patch
        let parts = versionString.split(separator: ".").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }

        self.major = parts[0]
        self.minor = parts[1]
        self.patch = parts.count > 2 ? parts[2] : 0

        // Parse pre-release if present
        if mainParts.count > 1 {
            self.preRelease = PreReleaseType.parse(String(mainParts[1]))
        } else {
            self.preRelease = .none
        }
    }

    init(major: Int, minor: Int, patch: Int, preRelease: PreReleaseType = .none) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.preRelease = preRelease
    }

    /// Compare versions: 1.0.0 > 1.0.0-beta.1 > 1.0.0-alpha.1
    /// But 1.0.1-alpha.1 > 1.0.0 (higher base version wins)
    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        // First compare major.minor.patch
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Same base version, compare pre-release
        // alpha < beta < stable (none)
        return lhs.preRelease < rhs.preRelease
    }

    /// Returns just the base version without pre-release suffix.
    var baseVersion: SemanticVersion {
        SemanticVersion(major: major, minor: minor, patch: patch, preRelease: .none)
    }
}

// MARK: - Update Error

/// Errors that can occur during update operations.
enum UpdateError: Error, LocalizedError, Sendable {
    case networkError(underlying: String)
    case noReleasesFound
    case noCompatibleAsset
    case downloadFailed(underlying: String)
    case installationFailed(underlying: String)
    case versionParsingFailed
    case rateLimited(retryAfter: Int?)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .noReleasesFound:
            return "No releases found on GitHub"
        case .noCompatibleAsset:
            return "No compatible download found for this Mac"
        case .downloadFailed(let msg):
            return "Download failed: \(msg)"
        case .installationFailed(let msg):
            return "Installation failed: \(msg)"
        case .versionParsingFailed:
            return "Could not parse version number"
        case .rateLimited(let retry):
            if let r = retry {
                return "Rate limited. Try again in \(r) seconds."
            }
            return "Rate limited. Please try again later."
        }
    }
}
