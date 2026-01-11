//
//  InstallationStateTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class InstallationStateTests: XCTestCase {

    // MARK: - InstallationLocation Equality

    func testInstallationLocationEquality() {
        XCTAssertEqual(InstallationLocation.applications, InstallationLocation.applications)
        XCTAssertEqual(InstallationLocation.userApplications, InstallationLocation.userApplications)
        XCTAssertEqual(InstallationLocation.downloads, InstallationLocation.downloads)
        XCTAssertEqual(InstallationLocation.dmg, InstallationLocation.dmg)
        XCTAssertEqual(InstallationLocation.other(path: "/test"), InstallationLocation.other(path: "/test"))
    }

    func testInstallationLocationInequality() {
        XCTAssertNotEqual(InstallationLocation.applications, InstallationLocation.userApplications)
        XCTAssertNotEqual(InstallationLocation.downloads, InstallationLocation.dmg)
        XCTAssertNotEqual(InstallationLocation.other(path: "/a"), InstallationLocation.other(path: "/b"))
    }

    // MARK: - isInstalled Property

    func testApplicationsIsInstalled() {
        XCTAssertTrue(InstallationLocation.applications.isInstalled)
    }

    func testUserApplicationsIsInstalled() {
        XCTAssertTrue(InstallationLocation.userApplications.isInstalled)
    }

    func testDownloadsIsNotInstalled() {
        XCTAssertFalse(InstallationLocation.downloads.isInstalled)
    }

    func testDmgIsNotInstalled() {
        XCTAssertFalse(InstallationLocation.dmg.isInstalled)
    }

    func testOtherIsNotInstalled() {
        XCTAssertFalse(InstallationLocation.other(path: "/some/path").isInstalled)
    }

    // MARK: - isReadOnly Property

    func testApplicationsIsNotReadOnly() {
        XCTAssertFalse(InstallationLocation.applications.isReadOnly)
    }

    func testUserApplicationsIsNotReadOnly() {
        XCTAssertFalse(InstallationLocation.userApplications.isReadOnly)
    }

    func testDownloadsIsNotReadOnly() {
        XCTAssertFalse(InstallationLocation.downloads.isReadOnly)
    }

    func testDmgIsReadOnly() {
        XCTAssertTrue(InstallationLocation.dmg.isReadOnly)
    }

    func testOtherIsNotReadOnly() {
        XCTAssertFalse(InstallationLocation.other(path: "/test").isReadOnly)
    }

    // MARK: - InstallationResult

    func testInstallationResultCases() {
        // Verify all cases exist and are distinct
        let moved = InstallationResult.moved
        let later = InstallationResult.later
        let runFromCurrent = InstallationResult.runFromCurrent

        // These should compile and be different values
        switch moved {
        case .moved: break
        case .later: XCTFail("Should be .moved")
        case .runFromCurrent: XCTFail("Should be .moved")
        }

        switch later {
        case .later: break
        case .moved: XCTFail("Should be .later")
        case .runFromCurrent: XCTFail("Should be .later")
        }

        switch runFromCurrent {
        case .runFromCurrent: break
        case .moved: XCTFail("Should be .runFromCurrent")
        case .later: XCTFail("Should be .runFromCurrent")
        }
    }

    // MARK: - Associated Values

    func testOtherLocationStoresPath() {
        let path = "/Users/test/Desktop/whisperX.app"
        let location = InstallationLocation.other(path: path)

        if case .other(let storedPath) = location {
            XCTAssertEqual(storedPath, path)
        } else {
            XCTFail("Expected .other case")
        }
    }

    func testOtherLocationWithEmptyPath() {
        let location = InstallationLocation.other(path: "")

        if case .other(let path) = location {
            XCTAssertEqual(path, "")
            XCTAssertFalse(location.isInstalled)
            XCTAssertFalse(location.isReadOnly)
        } else {
            XCTFail("Expected .other case")
        }
    }

    // MARK: - Installation Location Categories

    func testInstalledLocations() {
        let installedLocations: [InstallationLocation] = [
            .applications,
            .userApplications
        ]

        for location in installedLocations {
            XCTAssertTrue(location.isInstalled, "\(location) should be installed")
        }
    }

    func testNotInstalledLocations() {
        let notInstalledLocations: [InstallationLocation] = [
            .downloads,
            .dmg,
            .other(path: "/var/tmp/test.app")
        ]

        for location in notInstalledLocations {
            XCTAssertFalse(location.isInstalled, "\(location) should not be installed")
        }
    }
}
