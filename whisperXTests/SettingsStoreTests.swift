//
//  SettingsStoreTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

@MainActor
final class SettingsStoreTests: XCTestCase {

    private var suiteName: String!
    private var testDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use a unique suite name for test isolation
        suiteName = "com.whisperx.tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() async throws {
        // Clean up the test suite
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        suiteName = nil
        try await super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultHotkeyKeyCode() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyKeyCode, SettingsStore.defaultHotkeyKeyCode)
        XCTAssertEqual(store.hotkeyKeyCode, 61) // Right Option
    }

    func testDefaultHotkeyModifiers() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyModifiers, SettingsStore.defaultHotkeyModifiers)
        XCTAssertEqual(store.hotkeyModifiers, 0)
    }

    func testDefaultDebounceMs() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyDebounceMs, SettingsStore.defaultDebounceMs)
        XCTAssertEqual(store.hotkeyDebounceMs, 100)
    }

    func testDefaultModelVariant() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.modelVariant, .base)
    }

    func testDefaultAudioDeviceID() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertNil(store.audioDeviceID)
    }

    func testDefaultCopyToClipboard() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store.copyToClipboard)
    }

    func testDefaultPasteAfterCopy() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.pasteAfterCopy)
    }

    func testDefaultCheckUpdatesOnLaunch() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store.checkUpdatesOnLaunch)
    }

    func testDefaultAutoUpdateEnabled() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.autoUpdateEnabled)
    }

    func testDefaultInstallationWizardDismissed() {
        let store = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store.installationWizardDismissed)
    }

    // MARK: - Persistence

    func testHotkeyKeyCodePersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.hotkeyKeyCode = 49 // Space key

        // Create a new store instance to verify persistence
        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store2.hotkeyKeyCode, 49)
    }

    func testHotkeyModifiersPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.hotkeyModifiers = 256 // Some modifier

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store2.hotkeyModifiers, 256)
    }

    func testDebounceMsPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.hotkeyDebounceMs = 200

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store2.hotkeyDebounceMs, 200)
    }

    func testModelVariantPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.modelVariant = .large

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store2.modelVariant, .large)
    }

    func testAllModelVariantsPersistence() {
        for model in WhisperModel.allCases {
            let store = SettingsStore(defaults: testDefaults)
            store.modelVariant = model

            let store2 = SettingsStore(defaults: testDefaults)
            XCTAssertEqual(store2.modelVariant, model, "Failed for model: \(model)")
        }
    }

    func testAudioDeviceIDPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.audioDeviceID = "test-device-id"

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store2.audioDeviceID, "test-device-id")
    }

    func testAudioDeviceIDNilPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.audioDeviceID = "some-id"
        store.audioDeviceID = nil

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertNil(store2.audioDeviceID)
    }

    func testCopyToClipboardPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.copyToClipboard = false

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store2.copyToClipboard)
    }

    func testPasteAfterCopyPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.pasteAfterCopy = true

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store2.pasteAfterCopy)
    }

    func testCheckUpdatesOnLaunchPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.checkUpdatesOnLaunch = false

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertFalse(store2.checkUpdatesOnLaunch)
    }

    func testAutoUpdateEnabledPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.autoUpdateEnabled = true

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store2.autoUpdateEnabled)
    }

    func testInstallationWizardDismissedPersistence() {
        let store = SettingsStore(defaults: testDefaults)
        store.installationWizardDismissed = true

        let store2 = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(store2.installationWizardDismissed)
    }

    // MARK: - Edge Cases

    func testInvalidModelVariantFallsBackToBase() {
        // Set an invalid raw value directly in defaults
        testDefaults.set("invalid-model", forKey: "modelVariant")

        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.modelVariant, .base)
    }

    func testZeroKeyCodeUsesDefault() {
        testDefaults.set(0, forKey: "hotkeyKeyCode")

        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyKeyCode, SettingsStore.defaultHotkeyKeyCode)
    }

    func testZeroDebounceUsesDefault() {
        testDefaults.set(0, forKey: "hotkeyDebounceMs")

        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyDebounceMs, SettingsStore.defaultDebounceMs)
    }

    func testNegativeKeyCodeUsesDefault() {
        testDefaults.set(-1, forKey: "hotkeyKeyCode")

        let store = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(store.hotkeyKeyCode, SettingsStore.defaultHotkeyKeyCode)
    }

    // MARK: - Static Defaults

    func testStaticDefaultValues() {
        XCTAssertEqual(SettingsStore.defaultHotkeyKeyCode, 61)
        XCTAssertEqual(SettingsStore.defaultHotkeyModifiers, 0)
        XCTAssertEqual(SettingsStore.defaultDebounceMs, 100)
    }
}
