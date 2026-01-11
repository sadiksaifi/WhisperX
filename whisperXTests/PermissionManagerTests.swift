//
//  PermissionManagerTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class PermissionManagerTests: XCTestCase {

    // MARK: - PermissionType

    func testPermissionTypeCases() {
        // Verify all expected permission types exist
        let accessibility = PermissionType.accessibility
        let microphone = PermissionType.microphone

        switch accessibility {
        case .accessibility: break
        case .microphone: XCTFail("Should be accessibility")
        }

        switch microphone {
        case .microphone: break
        case .accessibility: XCTFail("Should be microphone")
        }
    }

    // MARK: - PermissionStatus Equality

    func testPermissionStatusEquality() {
        XCTAssertEqual(PermissionStatus.unknown, PermissionStatus.unknown)
        XCTAssertEqual(PermissionStatus.granted, PermissionStatus.granted)
        XCTAssertEqual(PermissionStatus.denied, PermissionStatus.denied)
        XCTAssertEqual(PermissionStatus.notDetermined, PermissionStatus.notDetermined)
    }

    func testPermissionStatusInequality() {
        XCTAssertNotEqual(PermissionStatus.unknown, PermissionStatus.granted)
        XCTAssertNotEqual(PermissionStatus.granted, PermissionStatus.denied)
        XCTAssertNotEqual(PermissionStatus.denied, PermissionStatus.notDetermined)
        XCTAssertNotEqual(PermissionStatus.notDetermined, PermissionStatus.unknown)
    }

    // MARK: - PermissionStatus Cases

    func testAllPermissionStatusCases() {
        let statuses: [PermissionStatus] = [
            .unknown,
            .granted,
            .denied,
            .notDetermined
        ]

        // Verify each status is distinct
        for (index, status) in statuses.enumerated() {
            for (otherIndex, otherStatus) in statuses.enumerated() {
                if index == otherIndex {
                    XCTAssertEqual(status, otherStatus)
                } else {
                    XCTAssertNotEqual(status, otherStatus)
                }
            }
        }
    }

    // MARK: - PermissionStatus Switch Exhaustiveness

    func testPermissionStatusSwitchExhaustiveness() {
        func describeStatus(_ status: PermissionStatus) -> String {
            switch status {
            case .unknown:
                return "unknown"
            case .granted:
                return "granted"
            case .denied:
                return "denied"
            case .notDetermined:
                return "not determined"
            }
        }

        XCTAssertEqual(describeStatus(.unknown), "unknown")
        XCTAssertEqual(describeStatus(.granted), "granted")
        XCTAssertEqual(describeStatus(.denied), "denied")
        XCTAssertEqual(describeStatus(.notDetermined), "not determined")
    }

    // MARK: - PermissionType Switch Exhaustiveness

    func testPermissionTypeSwitchExhaustiveness() {
        func describeType(_ type: PermissionType) -> String {
            switch type {
            case .accessibility:
                return "accessibility"
            case .microphone:
                return "microphone"
            }
        }

        XCTAssertEqual(describeType(.accessibility), "accessibility")
        XCTAssertEqual(describeType(.microphone), "microphone")
    }

    // MARK: - Permission Manager Guidance Flags

    @MainActor
    func testResetGuidanceFlagsClears() {
        // Store original values
        let accessibilityKey = "hasShownAccessibilityGuidance"
        let microphoneKey = "hasShownMicrophoneGuidance"

        // Set values
        UserDefaults.standard.set(true, forKey: accessibilityKey)
        UserDefaults.standard.set(true, forKey: microphoneKey)

        // Create manager and reset
        let manager = PermissionManager()
        manager.resetGuidanceFlags()

        // Verify cleared
        XCTAssertFalse(UserDefaults.standard.bool(forKey: accessibilityKey))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: microphoneKey))
    }

    @MainActor
    func testShouldShowAccessibilityGuidanceFirstTime() {
        let manager = PermissionManager()
        manager.resetGuidanceFlags()

        // First call should return true
        XCTAssertTrue(manager.shouldShowAccessibilityGuidance())

        // Subsequent calls should return false
        XCTAssertFalse(manager.shouldShowAccessibilityGuidance())
        XCTAssertFalse(manager.shouldShowAccessibilityGuidance())
    }

    @MainActor
    func testShouldShowMicrophoneGuidanceFirstTime() {
        let manager = PermissionManager()
        manager.resetGuidanceFlags()

        // First call should return true
        XCTAssertTrue(manager.shouldShowMicrophoneGuidance())

        // Subsequent calls should return false
        XCTAssertFalse(manager.shouldShowMicrophoneGuidance())
        XCTAssertFalse(manager.shouldShowMicrophoneGuidance())
    }

    @MainActor
    func testGuidanceFlagsAreIndependent() {
        let manager = PermissionManager()
        manager.resetGuidanceFlags()

        // Show accessibility guidance
        _ = manager.shouldShowAccessibilityGuidance()

        // Microphone guidance should still show
        XCTAssertTrue(manager.shouldShowMicrophoneGuidance())
    }
}
