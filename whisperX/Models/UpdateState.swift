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
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
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
        case let (.downloading(p1), .downloading(p2)):
            return p1 == p2
        case let (.error(m1), .error(m2)):
            return m1 == m2
        default:
            return false
        }
    }
}

// MARK: - Semantic Version

/// Parsed semantic version for comparison.
struct SemanticVersion: Comparable, Sendable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int

    var description: String {
        "\(major).\(minor).\(patch)"
    }

    /// Initializes from a version string like "1.0.0", "v1.0.0", or "1.0".
    init?(string: String) {
        let cleaned = string.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let parts = cleaned.split(separator: ".").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        self.major = parts[0]
        self.minor = parts[1]
        self.patch = parts.count > 2 ? parts[2] : 0
    }

    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
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
