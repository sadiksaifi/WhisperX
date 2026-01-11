//
//  ClipboardServiceTests.swift
//  whisperXTests
//

import XCTest
import AppKit
@testable import whisperX

final class ClipboardServiceTests: XCTestCase {

    // Store original clipboard content to restore after tests
    private var originalClipboardContent: String?

    override func setUp() {
        super.setUp()
        // Save original clipboard content
        originalClipboardContent = NSPasteboard.general.string(forType: .string)
    }

    override func tearDown() {
        // Restore original clipboard content
        if let original = originalClipboardContent {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(original, forType: .string)
        }
        super.tearDown()
    }

    // MARK: - Singleton

    func testSharedInstance() {
        let instance1 = ClipboardService.shared
        let instance2 = ClipboardService.shared

        XCTAssertTrue(instance1 === instance2, "Should be the same instance")
    }

    // MARK: - Copy Operations

    func testCopySimpleText() {
        let service = ClipboardService.shared
        let text = "Hello, World!"

        service.copy(text)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, text)
    }

    func testCopyEmptyString() {
        let service = ClipboardService.shared

        service.copy("")

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, "")
    }

    func testCopyOverwritesPreviousContent() {
        let service = ClipboardService.shared

        service.copy("First text")
        service.copy("Second text")

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, "Second text")
    }

    func testCopyLongText() {
        let service = ClipboardService.shared
        let longText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)

        service.copy(longText)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, longText)
    }

    func testCopyUnicodeText() {
        let service = ClipboardService.shared
        let unicodeText = "Hello World! Emoji: Check mark: Test"

        service.copy(unicodeText)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, unicodeText)
    }

    func testCopyMultilineText() {
        let service = ClipboardService.shared
        let multilineText = """
        Line 1
        Line 2
        Line 3
        """

        service.copy(multilineText)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, multilineText)
    }

    func testCopySpecialCharacters() {
        let service = ClipboardService.shared
        let specialText = "Tab:\tNewline:\nCarriage:\rQuotes:\"'`"

        service.copy(specialText)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, specialText)
    }

    func testCopyTextWithWhitespace() {
        let service = ClipboardService.shared
        let text = "   leading and trailing spaces   "

        service.copy(text)

        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertEqual(result, text)
    }

    // MARK: - Clipboard State

    func testCopyClearsExistingContent() {
        // Set up clipboard with multiple types
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Original", forType: .string)

        // Copy new text
        ClipboardService.shared.copy("New text")

        // Verify old content is replaced
        let result = pasteboard.string(forType: .string)
        XCTAssertEqual(result, "New text")
        XCTAssertNotEqual(result, "Original")
    }

    // MARK: - Thread Safety

    func testCopyConcurrently() async {
        let service = ClipboardService.shared
        let iterations = 100

        // Perform many concurrent copies
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    service.copy("Text \(i)")
                }
            }
        }

        // Verify clipboard has valid content (last write wins)
        let result = NSPasteboard.general.string(forType: .string)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.hasPrefix("Text "))
    }

    // MARK: - Note about Paste

    // Note: The paste() method uses CGEvent to simulate Cmd+V keystrokes.
    // This requires:
    // 1. Accessibility permission to be granted
    // 2. An active text field to receive input
    // 3. The system to process keyboard events
    //
    // Integration testing of paste() would require:
    // - A UI test target with proper entitlements
    // - A controlled environment with a text input
    //
    // Therefore, paste() is not unit tested here but should be
    // verified through manual testing or UI automation tests.
}
