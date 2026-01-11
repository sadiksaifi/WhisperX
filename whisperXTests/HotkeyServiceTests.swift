//
//  HotkeyServiceTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

// MARK: - Mock Delegate

final class MockHotkeyDelegate: HotkeyServiceDelegate {
    var pressCount = 0
    var releaseCount = 0
    var pressExpectation: XCTestExpectation?
    var releaseExpectation: XCTestExpectation?

    @MainActor
    func hotkeyDidPress() {
        pressCount += 1
        pressExpectation?.fulfill()
    }

    @MainActor
    func hotkeyDidRelease() {
        releaseCount += 1
        releaseExpectation?.fulfill()
    }

    func reset() {
        pressCount = 0
        releaseCount = 0
        pressExpectation = nil
        releaseExpectation = nil
    }
}

// MARK: - Tests

final class HotkeyServiceTests: XCTestCase {

    // MARK: - Configuration Constants

    func testDefaultDebounceInterval() {
        XCTAssertEqual(HotkeyService.defaultDebounceInterval, 0.1)
    }

    func testDefaultKeyCode() {
        // Right Option key
        XCTAssertEqual(HotkeyService.defaultKeyCode, 61)
    }

    func testFallbackKeyCode() {
        // F13 key
        XCTAssertEqual(HotkeyService.fallbackKeyCode, 105)
    }

    // MARK: - Initialization

    func testInitializationWithDefaults() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)

        XCTAssertEqual(service.activeKeyCode, HotkeyService.defaultKeyCode)
        XCTAssertEqual(service.activeModifiers, 0)
        XCTAssertEqual(service.debounceInterval, HotkeyService.defaultDebounceInterval)
        XCTAssertFalse(service.isRunning)
    }

    func testInitializationWithCustomKeyCode() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(
            delegate: delegate,
            keyCode: 49, // Space
            modifiers: 0,
            debounceInterval: 0.2
        )

        XCTAssertEqual(service.activeKeyCode, 49)
        XCTAssertEqual(service.debounceInterval, 0.2)
    }

    func testInitializationWithModifiers() {
        let delegate = MockHotkeyDelegate()
        let commandMask: UInt = 1 << 20 // Command key mask

        let service = HotkeyService(
            delegate: delegate,
            keyCode: 49,
            modifiers: commandMask,
            debounceInterval: 0.1
        )

        XCTAssertEqual(service.activeModifiers, commandMask)
    }

    func testInitializationWithNilDelegate() {
        let service = HotkeyService(delegate: nil)

        XCTAssertEqual(service.activeKeyCode, HotkeyService.defaultKeyCode)
        XCTAssertFalse(service.isRunning)
    }

    // MARK: - Hotkey Update

    func testUpdateHotkeyChangesKeyCode() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)

        service.updateHotkey(keyCode: 49, modifiers: 0)

        XCTAssertEqual(service.activeKeyCode, 49)
    }

    func testUpdateHotkeyChangesModifiers() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)
        let modifiers: UInt = 256

        service.updateHotkey(keyCode: 49, modifiers: modifiers)

        XCTAssertEqual(service.activeModifiers, modifiers)
    }

    func testUpdateHotkeyDefaultModifiers() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate, modifiers: 256)

        service.updateHotkey(keyCode: 50) // No modifiers specified

        XCTAssertEqual(service.activeKeyCode, 50)
        XCTAssertEqual(service.activeModifiers, 0)
    }

    // MARK: - Debounce Interval

    func testDebounceIntervalCanBeChanged() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)

        service.debounceInterval = 0.25

        XCTAssertEqual(service.debounceInterval, 0.25)
    }

    func testDebounceIntervalAcceptsZero() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate, debounceInterval: 0)

        XCTAssertEqual(service.debounceInterval, 0)
    }

    // MARK: - Running State

    func testInitiallyNotRunning() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)

        XCTAssertFalse(service.isRunning)
    }

    func testStopWhenNotRunning() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)

        // Should not crash when stopping a non-running service
        service.stop()

        XCTAssertFalse(service.isRunning)
    }

    // MARK: - Key Code Values

    func testCommonKeyCodeValues() {
        // Verify the service accepts common key codes
        let delegate = MockHotkeyDelegate()

        let keyCodes: [CGKeyCode] = [
            49,  // Space
            61,  // Right Option
            58,  // Left Option
            36,  // Return
            53,  // Escape
            105, // F13
            106, // F14
            107, // F15
            63,  // Fn (legacy)
        ]

        for keyCode in keyCodes {
            let service = HotkeyService(delegate: delegate, keyCode: keyCode)
            XCTAssertEqual(service.activeKeyCode, keyCode, "Failed for key code \(keyCode)")
        }
    }

    // MARK: - Modifier Flag Values

    func testModifierFlagValues() {
        let delegate = MockHotkeyDelegate()

        // Common modifier flag combinations
        let modifierTests: [(UInt, String)] = [
            (0, "None"),
            (1 << 17, "Shift"),
            (1 << 18, "Control"),
            (1 << 19, "Option"),
            (1 << 20, "Command"),
            ((1 << 20) | (1 << 17), "Command+Shift"),
        ]

        for (modifiers, name) in modifierTests {
            let service = HotkeyService(delegate: delegate, modifiers: modifiers)
            XCTAssertEqual(service.activeModifiers, modifiers, "Failed for \(name)")
        }
    }

    // MARK: - Delegate Reference

    func testDelegateIsWeaklyHeld() {
        var delegate: MockHotkeyDelegate? = MockHotkeyDelegate()
        weak var weakDelegate = delegate

        let service = HotkeyService(delegate: delegate)
        _ = service // Keep service alive

        delegate = nil

        // Delegate should be deallocated
        XCTAssertNil(weakDelegate)
    }

    // MARK: - Note about Start/Stop

    // Note: Testing start() and stop() with actual CGEventTap requires:
    // 1. Accessibility permission to be granted
    // 2. The app to be signed with appropriate entitlements
    // 3. A real event loop to process events
    //
    // In a CI/test environment, CGEventTap creation will fail due to
    // missing Accessibility permission, which is expected behavior.
    //
    // The start() method handles this gracefully by:
    // - Checking AXIsProcessTrusted() first
    // - Returning false if permission is denied
    // - Falling back to F13 if the configured key fails
    //
    // Full integration testing of hotkey capture should be done
    // in a privileged environment or through manual testing.

    func testStartWithoutAccessibilityPermission() {
        let delegate = MockHotkeyDelegate()
        let service = HotkeyService(delegate: delegate)

        // This will fail in test environment due to no Accessibility permission
        let started = service.start()

        // In test environment without permission, this should return false
        // or true if somehow permission is granted (e.g., running in Xcode with permission)
        if !started {
            XCTAssertFalse(service.isRunning)
        }
    }
}
