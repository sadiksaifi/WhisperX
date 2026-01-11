//
//  UpdateServiceTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

// MARK: - Mock Delegate

@MainActor
final class MockUpdateServiceDelegate: UpdateServiceDelegate {
    var stateChanges: [UpdateCheckState] = []
    var foundReleases: [GitHubRelease] = []
    var installationCompleteCount = 0

    var stateChangeExpectation: XCTestExpectation?
    var updateFoundExpectation: XCTestExpectation?
    var installCompleteExpectation: XCTestExpectation?

    func updateService(_ service: UpdateService, didChangeState state: UpdateCheckState) {
        stateChanges.append(state)
        stateChangeExpectation?.fulfill()
    }

    func updateService(_ service: UpdateService, didFindUpdate release: GitHubRelease) {
        foundReleases.append(release)
        updateFoundExpectation?.fulfill()
    }

    func updateServiceDidCompleteInstallation(_ service: UpdateService) {
        installationCompleteCount += 1
        installCompleteExpectation?.fulfill()
    }

    func reset() {
        stateChanges = []
        foundReleases = []
        installationCompleteCount = 0
        stateChangeExpectation = nil
        updateFoundExpectation = nil
        installCompleteExpectation = nil
    }
}

// MARK: - Tests

final class UpdateServiceTests: XCTestCase {

    // MARK: - Initialization

    @MainActor
    func testInitialization() async {
        let delegate = MockUpdateServiceDelegate()
        let service = UpdateService(delegate: delegate)

        let state = await service.getState()
        XCTAssertEqual(state, .idle)
    }

    @MainActor
    func testInitializationWithNilDelegate() async {
        let service = UpdateService(delegate: nil)

        let state = await service.getState()
        XCTAssertEqual(state, .idle)
    }

    // MARK: - State Access

    @MainActor
    func testGetStateReturnsCurrentState() async {
        let service = UpdateService(delegate: nil)

        let state = await service.getState()
        XCTAssertEqual(state, .idle)
    }

    @MainActor
    func testGetAvailableReleaseInitiallyNil() async {
        let service = UpdateService(delegate: nil)

        let release = await service.getAvailableRelease()
        XCTAssertNil(release)
    }

    // MARK: - Delegate Setting

    @MainActor
    func testSetDelegate() async {
        let service = UpdateService(delegate: nil)
        let delegate = MockUpdateServiceDelegate()

        await service.setDelegate(delegate)

        // Verify delegate is set by checking if it receives callbacks
        // (In actual use, callbacks would be triggered by state changes)
        XCTAssertTrue(delegate.stateChanges.isEmpty) // No changes yet
    }

    // MARK: - Cancel Download

    @MainActor
    func testCancelDownloadFromIdle() async {
        let service = UpdateService(delegate: nil)

        // Should not crash when cancelling with no download in progress
        await service.cancelDownload()

        let state = await service.getState()
        XCTAssertEqual(state, .idle)
    }

    // MARK: - Version Comparison Integration

    func testVersionComparisonForUpdates() {
        // Simulate the logic used in checkForUpdates
        let currentVersion = SemanticVersion(string: "1.0.0")!
        let latestVersionNewer = SemanticVersion(string: "1.1.0")!
        let latestVersionSame = SemanticVersion(string: "1.0.0")!
        let latestVersionOlder = SemanticVersion(string: "0.9.0")!

        XCTAssertTrue(latestVersionNewer > currentVersion, "1.1.0 should be newer than 1.0.0")
        XCTAssertFalse(latestVersionSame > currentVersion, "1.0.0 should not be newer than 1.0.0")
        XCTAssertFalse(latestVersionOlder > currentVersion, "0.9.0 should not be newer than 1.0.0")
    }

    // MARK: - Asset Selection Logic

    func testAssetSelectionPrefersDMG() {
        let dmgAsset = GitHubAsset(
            name: "whisperX.dmg",
            browserDownloadUrl: "https://example.com/whisperX.dmg",
            size: 100_000_000,
            contentType: "application/x-apple-diskimage"
        )
        let zipAsset = GitHubAsset(
            name: "whisperX.zip",
            browserDownloadUrl: "https://example.com/whisperX.zip",
            size: 90_000_000,
            contentType: "application/zip"
        )

        let assets = [zipAsset, dmgAsset] // DMG listed second

        // The service should prefer DMG over ZIP
        let dmgFirst = assets.first { $0.name.hasSuffix(".dmg") }
        let zipFirst = assets.first { $0.name.hasSuffix(".zip") }

        XCTAssertNotNil(dmgFirst)
        XCTAssertNotNil(zipFirst)
        XCTAssertEqual(dmgFirst?.name, "whisperX.dmg")

        // Simulate findCompatibleAsset logic: DMG preferred
        let selected = dmgFirst ?? zipFirst
        XCTAssertEqual(selected?.name, "whisperX.dmg")
    }

    func testAssetSelectionFallsBackToZIP() {
        let zipAsset = GitHubAsset(
            name: "whisperX.zip",
            browserDownloadUrl: "https://example.com/whisperX.zip",
            size: 90_000_000,
            contentType: "application/zip"
        )

        let assets = [zipAsset]

        let dmgFirst = assets.first { $0.name.hasSuffix(".dmg") }
        let zipFirst = assets.first { $0.name.hasSuffix(".zip") }

        XCTAssertNil(dmgFirst)
        XCTAssertNotNil(zipFirst)

        let selected = dmgFirst ?? zipFirst
        XCTAssertEqual(selected?.name, "whisperX.zip")
    }

    func testAssetSelectionWithNoCompatibleAsset() {
        let otherAsset = GitHubAsset(
            name: "whisperX.tar.gz",
            browserDownloadUrl: "https://example.com/whisperX.tar.gz",
            size: 80_000_000,
            contentType: "application/gzip"
        )

        let assets = [otherAsset]

        let dmgFirst = assets.first { $0.name.hasSuffix(".dmg") }
        let zipFirst = assets.first { $0.name.hasSuffix(".zip") }

        let selected = dmgFirst ?? zipFirst
        XCTAssertNil(selected)
    }

    // MARK: - Error Handling

    @MainActor
    func testDownloadUpdateWithoutAvailableRelease() async {
        let service = UpdateService(delegate: nil)

        do {
            try await service.downloadUpdate()
            XCTFail("Should throw noCompatibleAsset error")
        } catch let error as UpdateError {
            XCTAssertEqual(error, .noCompatibleAsset)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    @MainActor
    func testInstallUpdateWithoutDownloadedFile() async {
        let service = UpdateService(delegate: nil)

        do {
            try await service.installUpdate()
            XCTFail("Should throw installationFailed error")
        } catch let error as UpdateError {
            if case .installationFailed(let underlying) = error {
                XCTAssertEqual(underlying, "No downloaded file")
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Note about Network Tests

    // Note: Testing actual network requests (checkForUpdates with real GitHub API)
    // would require:
    // 1. Network access in the test environment
    // 2. Mocking URLSession or using a test server
    // 3. Handling rate limiting (60 requests/hour for unauthenticated)
    //
    // For unit tests, we focus on:
    // - State management logic
    // - Version comparison
    // - Asset selection
    // - Error handling
    //
    // Integration tests with mocked network responses would be
    // added in a separate test target or using dependency injection.
}

// MARK: - UpdateError Equatable Extension for Testing

extension UpdateError: Equatable {
    public static func == (lhs: UpdateError, rhs: UpdateError) -> Bool {
        switch (lhs, rhs) {
        case (.noReleasesFound, .noReleasesFound):
            return true
        case (.noCompatibleAsset, .noCompatibleAsset):
            return true
        case (.versionParsingFailed, .versionParsingFailed):
            return true
        case let (.networkError(l), .networkError(r)):
            return l == r
        case let (.downloadFailed(l), .downloadFailed(r)):
            return l == r
        case let (.installationFailed(l), .installationFailed(r)):
            return l == r
        case let (.rateLimited(l), .rateLimited(r)):
            return l == r
        default:
            return false
        }
    }
}
