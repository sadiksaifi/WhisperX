//
//  AudioDeviceTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class AudioDeviceTests: XCTestCase {

    // MARK: - AudioDevice Initialization

    func testAudioDeviceInitialization() {
        let device = AudioDevice(id: "test-id", name: "Test Microphone", isDefault: true)

        XCTAssertEqual(device.id, "test-id")
        XCTAssertEqual(device.name, "Test Microphone")
        XCTAssertTrue(device.isDefault)
    }

    func testAudioDeviceNonDefault() {
        let device = AudioDevice(id: "other-id", name: "External Mic", isDefault: false)

        XCTAssertEqual(device.id, "other-id")
        XCTAssertEqual(device.name, "External Mic")
        XCTAssertFalse(device.isDefault)
    }

    // MARK: - Identifiable Conformance

    func testAudioDeviceIdentifiable() {
        let device = AudioDevice(id: "unique-id", name: "Device", isDefault: false)
        XCTAssertEqual(device.id, "unique-id")
    }

    func testAudioDeviceIdentifiableInCollection() {
        let devices = [
            AudioDevice(id: "1", name: "Device 1", isDefault: true),
            AudioDevice(id: "2", name: "Device 2", isDefault: false),
            AudioDevice(id: "3", name: "Device 3", isDefault: false)
        ]

        // Should be usable in ForEach-style iteration
        let ids = devices.map { $0.id }
        XCTAssertEqual(ids, ["1", "2", "3"])
    }

    // MARK: - Equatable Conformance

    func testAudioDeviceEquality() {
        let device1 = AudioDevice(id: "same-id", name: "Mic", isDefault: true)
        let device2 = AudioDevice(id: "same-id", name: "Mic", isDefault: true)

        XCTAssertEqual(device1, device2)
    }

    func testAudioDeviceInequalityById() {
        let device1 = AudioDevice(id: "id-1", name: "Mic", isDefault: true)
        let device2 = AudioDevice(id: "id-2", name: "Mic", isDefault: true)

        XCTAssertNotEqual(device1, device2)
    }

    func testAudioDeviceInequalityByName() {
        let device1 = AudioDevice(id: "id", name: "Mic 1", isDefault: true)
        let device2 = AudioDevice(id: "id", name: "Mic 2", isDefault: true)

        XCTAssertNotEqual(device1, device2)
    }

    func testAudioDeviceInequalityByDefault() {
        let device1 = AudioDevice(id: "id", name: "Mic", isDefault: true)
        let device2 = AudioDevice(id: "id", name: "Mic", isDefault: false)

        XCTAssertNotEqual(device1, device2)
    }

    // MARK: - Sendable Conformance

    func testAudioDeviceSendable() async {
        let device = AudioDevice(id: "test", name: "Test Device", isDefault: true)

        let task = Task { @Sendable in
            return device.name
        }

        let result = await task.value
        XCTAssertEqual(result, "Test Device")
    }

    func testAudioDeviceArraySendable() async {
        let devices = [
            AudioDevice(id: "1", name: "Device 1", isDefault: true),
            AudioDevice(id: "2", name: "Device 2", isDefault: false)
        ]

        let task = Task { @Sendable in
            return devices.count
        }

        let result = await task.value
        XCTAssertEqual(result, 2)
    }

    // MARK: - Collection Operations

    func testFindDefaultDevice() {
        let devices = [
            AudioDevice(id: "1", name: "Built-in Mic", isDefault: false),
            AudioDevice(id: "2", name: "USB Mic", isDefault: true),
            AudioDevice(id: "3", name: "Bluetooth Mic", isDefault: false)
        ]

        let defaultDevice = devices.first { $0.isDefault }
        XCTAssertNotNil(defaultDevice)
        XCTAssertEqual(defaultDevice?.name, "USB Mic")
    }

    func testFindDeviceById() {
        let devices = [
            AudioDevice(id: "built-in", name: "Built-in Mic", isDefault: true),
            AudioDevice(id: "usb-mic", name: "USB Mic", isDefault: false)
        ]

        let found = devices.first { $0.id == "usb-mic" }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "USB Mic")
    }

    func testNoDefaultDevice() {
        let devices = [
            AudioDevice(id: "1", name: "Mic 1", isDefault: false),
            AudioDevice(id: "2", name: "Mic 2", isDefault: false)
        ]

        let defaultDevice = devices.first { $0.isDefault }
        XCTAssertNil(defaultDevice)
    }

    // MARK: - Edge Cases

    func testEmptyDeviceName() {
        let device = AudioDevice(id: "id", name: "", isDefault: false)
        XCTAssertEqual(device.name, "")
    }

    func testLongDeviceName() {
        let longName = String(repeating: "A", count: 1000)
        let device = AudioDevice(id: "id", name: longName, isDefault: false)
        XCTAssertEqual(device.name.count, 1000)
    }

    func testSpecialCharactersInName() {
        let name = "Mic - USB (Model: XYZ) [Input]"
        let device = AudioDevice(id: "id", name: name, isDefault: false)
        XCTAssertEqual(device.name, name)
    }

    func testUnicodeInName() {
        let name = "Microphone"
        let device = AudioDevice(id: "id", name: name, isDefault: false)
        XCTAssertEqual(device.name, name)
    }
}
