//
//  UpdateStateTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class UpdateStateTests: XCTestCase {

    // MARK: - SemanticVersion Initialization

    func testSemanticVersionFromFullString() {
        let version = SemanticVersion(string: "1.2.3")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.major, 1)
        XCTAssertEqual(version?.minor, 2)
        XCTAssertEqual(version?.patch, 3)
    }

    func testSemanticVersionFromTwoPartString() {
        let version = SemanticVersion(string: "1.2")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.major, 1)
        XCTAssertEqual(version?.minor, 2)
        XCTAssertEqual(version?.patch, 0)
    }

    func testSemanticVersionWithVPrefix() {
        let version = SemanticVersion(string: "v1.2.3")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.major, 1)
        XCTAssertEqual(version?.minor, 2)
        XCTAssertEqual(version?.patch, 3)
    }

    func testSemanticVersionWithUppercaseVPrefix() {
        let version = SemanticVersion(string: "V1.2.3")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.major, 1)
        XCTAssertEqual(version?.minor, 2)
        XCTAssertEqual(version?.patch, 3)
    }

    func testSemanticVersionInvalidSinglePart() {
        let version = SemanticVersion(string: "1")
        XCTAssertNil(version)
    }

    func testSemanticVersionInvalidEmpty() {
        let version = SemanticVersion(string: "")
        XCTAssertNil(version)
    }

    func testSemanticVersionInvalidNonNumeric() {
        let version = SemanticVersion(string: "a.b.c")
        XCTAssertNil(version)
    }

    func testSemanticVersionDirectInit() {
        let version = SemanticVersion(major: 2, minor: 5, patch: 10)
        XCTAssertEqual(version.major, 2)
        XCTAssertEqual(version.minor, 5)
        XCTAssertEqual(version.patch, 10)
    }

    // MARK: - SemanticVersion Description

    func testSemanticVersionDescription() {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3)
        XCTAssertEqual(version.description, "1.2.3")
    }

    func testSemanticVersionDescriptionZeroPatch() {
        let version = SemanticVersion(major: 1, minor: 0, patch: 0)
        XCTAssertEqual(version.description, "1.0.0")
    }

    // MARK: - SemanticVersion Comparison

    func testSemanticVersionEqualityFull() {
        let v1 = SemanticVersion(major: 1, minor: 2, patch: 3)
        let v2 = SemanticVersion(major: 1, minor: 2, patch: 3)
        XCTAssertEqual(v1, v2)
    }

    func testSemanticVersionLessThanMajor() {
        let v1 = SemanticVersion(major: 1, minor: 0, patch: 0)
        let v2 = SemanticVersion(major: 2, minor: 0, patch: 0)
        XCTAssertLessThan(v1, v2)
    }

    func testSemanticVersionLessThanMinor() {
        let v1 = SemanticVersion(major: 1, minor: 1, patch: 0)
        let v2 = SemanticVersion(major: 1, minor: 2, patch: 0)
        XCTAssertLessThan(v1, v2)
    }

    func testSemanticVersionLessThanPatch() {
        let v1 = SemanticVersion(major: 1, minor: 2, patch: 3)
        let v2 = SemanticVersion(major: 1, minor: 2, patch: 4)
        XCTAssertLessThan(v1, v2)
    }

    func testSemanticVersionGreaterThan() {
        let v1 = SemanticVersion(major: 2, minor: 0, patch: 0)
        let v2 = SemanticVersion(major: 1, minor: 9, patch: 9)
        XCTAssertGreaterThan(v1, v2)
    }

    func testSemanticVersionComparable() {
        let versions = [
            SemanticVersion(major: 1, minor: 2, patch: 3),
            SemanticVersion(major: 1, minor: 0, patch: 0),
            SemanticVersion(major: 2, minor: 0, patch: 0),
            SemanticVersion(major: 1, minor: 2, patch: 0),
        ]

        let sorted = versions.sorted()
        XCTAssertEqual(sorted[0].description, "1.0.0")
        XCTAssertEqual(sorted[1].description, "1.2.0")
        XCTAssertEqual(sorted[2].description, "1.2.3")
        XCTAssertEqual(sorted[3].description, "2.0.0")
    }

    // MARK: - UpdateCheckState Equality

    func testUpdateCheckStateIdleEquality() {
        XCTAssertEqual(UpdateCheckState.idle, UpdateCheckState.idle)
    }

    func testUpdateCheckStateCheckingEquality() {
        XCTAssertEqual(UpdateCheckState.checking, UpdateCheckState.checking)
    }

    func testUpdateCheckStateUpToDateEquality() {
        XCTAssertEqual(UpdateCheckState.upToDate, UpdateCheckState.upToDate)
    }

    func testUpdateCheckStateReadyToInstallEquality() {
        XCTAssertEqual(UpdateCheckState.readyToInstall, UpdateCheckState.readyToInstall)
    }

    func testUpdateCheckStateInstallingEquality() {
        XCTAssertEqual(UpdateCheckState.installing, UpdateCheckState.installing)
    }

    func testUpdateCheckStateDownloadingEquality() {
        XCTAssertEqual(
            UpdateCheckState.downloading(progress: 0.5),
            UpdateCheckState.downloading(progress: 0.5)
        )
    }

    func testUpdateCheckStateDownloadingInequality() {
        XCTAssertNotEqual(
            UpdateCheckState.downloading(progress: 0.5),
            UpdateCheckState.downloading(progress: 0.6)
        )
    }

    func testUpdateCheckStateErrorEquality() {
        XCTAssertEqual(
            UpdateCheckState.error(message: "test"),
            UpdateCheckState.error(message: "test")
        )
    }

    func testUpdateCheckStateErrorInequality() {
        XCTAssertNotEqual(
            UpdateCheckState.error(message: "test1"),
            UpdateCheckState.error(message: "test2")
        )
    }

    func testUpdateCheckStateAvailableEquality() {
        let release = createMockRelease(tagName: "v1.0.0")
        XCTAssertEqual(
            UpdateCheckState.available(version: "v1.0.0", release: release),
            UpdateCheckState.available(version: "v1.0.0", release: release)
        )
    }

    func testUpdateCheckStateAvailableInequalityByVersion() {
        let release = createMockRelease(tagName: "v1.0.0")
        XCTAssertNotEqual(
            UpdateCheckState.available(version: "v1.0.0", release: release),
            UpdateCheckState.available(version: "v2.0.0", release: release)
        )
    }

    func testUpdateCheckStateDifferentStatesInequality() {
        XCTAssertNotEqual(UpdateCheckState.idle, UpdateCheckState.checking)
        XCTAssertNotEqual(UpdateCheckState.checking, UpdateCheckState.upToDate)
        XCTAssertNotEqual(UpdateCheckState.upToDate, UpdateCheckState.installing)
    }

    // MARK: - UpdateError

    func testUpdateErrorNetworkErrorDescription() {
        let error = UpdateError.networkError(underlying: "Connection failed")
        XCTAssertEqual(error.errorDescription, "Network error: Connection failed")
    }

    func testUpdateErrorNoReleasesFoundDescription() {
        let error = UpdateError.noReleasesFound
        XCTAssertEqual(error.errorDescription, "No releases found on GitHub")
    }

    func testUpdateErrorNoCompatibleAssetDescription() {
        let error = UpdateError.noCompatibleAsset
        XCTAssertEqual(error.errorDescription, "No compatible download found for this Mac")
    }

    func testUpdateErrorDownloadFailedDescription() {
        let error = UpdateError.downloadFailed(underlying: "Timeout")
        XCTAssertEqual(error.errorDescription, "Download failed: Timeout")
    }

    func testUpdateErrorInstallationFailedDescription() {
        let error = UpdateError.installationFailed(underlying: "Permission denied")
        XCTAssertEqual(error.errorDescription, "Installation failed: Permission denied")
    }

    func testUpdateErrorVersionParsingFailedDescription() {
        let error = UpdateError.versionParsingFailed
        XCTAssertEqual(error.errorDescription, "Could not parse version number")
    }

    func testUpdateErrorRateLimitedWithRetryDescription() {
        let error = UpdateError.rateLimited(retryAfter: 60)
        XCTAssertEqual(error.errorDescription, "Rate limited. Try again in 60 seconds.")
    }

    func testUpdateErrorRateLimitedWithoutRetryDescription() {
        let error = UpdateError.rateLimited(retryAfter: nil)
        XCTAssertEqual(error.errorDescription, "Rate limited. Please try again later.")
    }

    // MARK: - GitHubRelease Codable

    func testGitHubReleaseCodable() throws {
        let json = """
        {
            "tag_name": "v1.0.0",
            "name": "Release 1.0.0",
            "body": "Release notes",
            "html_url": "https://github.com/test/repo/releases/v1.0.0",
            "published_at": "2024-01-01T00:00:00Z",
            "assets": []
        }
        """

        let data = json.data(using: .utf8)!
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        XCTAssertEqual(release.tagName, "v1.0.0")
        XCTAssertEqual(release.name, "Release 1.0.0")
        XCTAssertEqual(release.body, "Release notes")
        XCTAssertEqual(release.htmlUrl, "https://github.com/test/repo/releases/v1.0.0")
        XCTAssertEqual(release.publishedAt, "2024-01-01T00:00:00Z")
        XCTAssertTrue(release.assets.isEmpty)
    }

    func testGitHubReleaseWithAssets() throws {
        let json = """
        {
            "tag_name": "v1.0.0",
            "name": "Release 1.0.0",
            "body": "Release notes",
            "html_url": "https://github.com/test/repo/releases/v1.0.0",
            "published_at": "2024-01-01T00:00:00Z",
            "assets": [
                {
                    "name": "app.dmg",
                    "browser_download_url": "https://example.com/app.dmg",
                    "size": 12345,
                    "content_type": "application/x-apple-diskimage"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)

        XCTAssertEqual(release.assets.count, 1)
        XCTAssertEqual(release.assets[0].name, "app.dmg")
        XCTAssertEqual(release.assets[0].browserDownloadUrl, "https://example.com/app.dmg")
        XCTAssertEqual(release.assets[0].size, 12345)
        XCTAssertEqual(release.assets[0].contentType, "application/x-apple-diskimage")
    }

    // MARK: - GitHubAsset Codable

    func testGitHubAssetCodable() throws {
        let json = """
        {
            "name": "whisperX.zip",
            "browser_download_url": "https://example.com/download.zip",
            "size": 50000000,
            "content_type": "application/zip"
        }
        """

        let data = json.data(using: .utf8)!
        let asset = try JSONDecoder().decode(GitHubAsset.self, from: data)

        XCTAssertEqual(asset.name, "whisperX.zip")
        XCTAssertEqual(asset.browserDownloadUrl, "https://example.com/download.zip")
        XCTAssertEqual(asset.size, 50000000)
        XCTAssertEqual(asset.contentType, "application/zip")
    }

    // MARK: - Sendable Conformance

    func testSemanticVersionSendable() async {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3)
        let task = Task { @Sendable in
            return version.description
        }
        let result = await task.value
        XCTAssertEqual(result, "1.2.3")
    }

    func testUpdateCheckStateSendable() async {
        let state = UpdateCheckState.checking
        let task = Task { @Sendable in
            return state == .checking
        }
        let result = await task.value
        XCTAssertTrue(result)
    }

    // MARK: - Helper Methods

    private func createMockRelease(tagName: String) -> GitHubRelease {
        GitHubRelease(
            tagName: tagName,
            name: "Test Release",
            body: "Test body",
            htmlUrl: "https://github.com/test/releases/\(tagName)",
            publishedAt: "2024-01-01T00:00:00Z",
            assets: []
        )
    }
}
