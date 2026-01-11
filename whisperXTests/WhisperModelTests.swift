//
//  WhisperModelTests.swift
//  whisperXTests
//

import XCTest
@testable import whisperX

final class WhisperModelTests: XCTestCase {

    // MARK: - All Cases

    func testAllCases() {
        let allCases = WhisperModel.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.tiny))
        XCTAssertTrue(allCases.contains(.base))
        XCTAssertTrue(allCases.contains(.small))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.large))
        XCTAssertTrue(allCases.contains(.largeTurbo))
    }

    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(WhisperModel.tiny.rawValue, "openai_whisper-tiny")
        XCTAssertEqual(WhisperModel.base.rawValue, "openai_whisper-base")
        XCTAssertEqual(WhisperModel.small.rawValue, "openai_whisper-small")
        XCTAssertEqual(WhisperModel.medium.rawValue, "openai_whisper-medium")
        XCTAssertEqual(WhisperModel.large.rawValue, "openai_whisper-large-v3")
        XCTAssertEqual(WhisperModel.largeTurbo.rawValue, "openai_whisper-large-v3-turbo")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(WhisperModel(rawValue: "openai_whisper-tiny"), .tiny)
        XCTAssertEqual(WhisperModel(rawValue: "openai_whisper-base"), .base)
        XCTAssertEqual(WhisperModel(rawValue: "openai_whisper-small"), .small)
        XCTAssertEqual(WhisperModel(rawValue: "openai_whisper-medium"), .medium)
        XCTAssertEqual(WhisperModel(rawValue: "openai_whisper-large-v3"), .large)
        XCTAssertEqual(WhisperModel(rawValue: "openai_whisper-large-v3-turbo"), .largeTurbo)
        XCTAssertNil(WhisperModel(rawValue: "invalid"))
    }

    // MARK: - Identifiable

    func testIdentifiable() {
        XCTAssertEqual(WhisperModel.tiny.id, "openai_whisper-tiny")
        XCTAssertEqual(WhisperModel.base.id, "openai_whisper-base")
        XCTAssertEqual(WhisperModel.large.id, "openai_whisper-large-v3")
    }

    // MARK: - Display Names

    func testDisplayNames() {
        XCTAssertEqual(WhisperModel.tiny.displayName, "Tiny")
        XCTAssertEqual(WhisperModel.base.displayName, "Base")
        XCTAssertEqual(WhisperModel.small.displayName, "Small")
        XCTAssertEqual(WhisperModel.medium.displayName, "Medium")
        XCTAssertEqual(WhisperModel.large.displayName, "Large v3")
        XCTAssertEqual(WhisperModel.largeTurbo.displayName, "Large v3 Turbo")
    }

    // MARK: - WhisperKit Model Names

    func testWhisperKitModelNames() {
        // WhisperKit model name should match raw value
        for model in WhisperModel.allCases {
            XCTAssertEqual(model.whisperKitModelName, model.rawValue)
        }
    }

    // MARK: - Parameter Counts

    func testParameterCounts() {
        XCTAssertEqual(WhisperModel.tiny.parameterCountMillions, 39)
        XCTAssertEqual(WhisperModel.base.parameterCountMillions, 74)
        XCTAssertEqual(WhisperModel.small.parameterCountMillions, 244)
        XCTAssertEqual(WhisperModel.medium.parameterCountMillions, 769)
        XCTAssertEqual(WhisperModel.large.parameterCountMillions, 1550)
        XCTAssertEqual(WhisperModel.largeTurbo.parameterCountMillions, 809)
    }

    func testParameterCountsAreOrdered() {
        // Verify parameter counts increase with model size (except turbo)
        XCTAssertLessThan(WhisperModel.tiny.parameterCountMillions, WhisperModel.base.parameterCountMillions)
        XCTAssertLessThan(WhisperModel.base.parameterCountMillions, WhisperModel.small.parameterCountMillions)
        XCTAssertLessThan(WhisperModel.small.parameterCountMillions, WhisperModel.medium.parameterCountMillions)
        XCTAssertLessThan(WhisperModel.medium.parameterCountMillions, WhisperModel.large.parameterCountMillions)
    }

    // MARK: - Memory Requirements

    func testMemoryRequirements() {
        XCTAssertEqual(WhisperModel.tiny.memoryRequirementGB, 0.5)
        XCTAssertEqual(WhisperModel.base.memoryRequirementGB, 0.7)
        XCTAssertEqual(WhisperModel.small.memoryRequirementGB, 1.5)
        XCTAssertEqual(WhisperModel.medium.memoryRequirementGB, 3.0)
        XCTAssertEqual(WhisperModel.large.memoryRequirementGB, 6.0)
        XCTAssertEqual(WhisperModel.largeTurbo.memoryRequirementGB, 3.5)
    }

    func testMemoryRequirementsArePositive() {
        for model in WhisperModel.allCases {
            XCTAssertGreaterThan(model.memoryRequirementGB, 0)
        }
    }

    // MARK: - Recommended Use Cases

    func testRecommendedUseCases() {
        // Verify all models have non-empty use case descriptions
        for model in WhisperModel.allCases {
            XCTAssertFalse(model.recommendedUseCase.isEmpty)
        }
    }

    func testSpecificUseCases() {
        XCTAssertTrue(WhisperModel.tiny.recommendedUseCase.contains("low-memory"))
        XCTAssertTrue(WhisperModel.base.recommendedUseCase.contains("balance"))
        XCTAssertTrue(WhisperModel.large.recommendedUseCase.contains("accuracy"))
        XCTAssertTrue(WhisperModel.largeTurbo.recommendedUseCase.contains("faster"))
    }

    // MARK: - Speed Ratings

    func testSpeedRatings() {
        XCTAssertEqual(WhisperModel.tiny.speedRating, 5)
        XCTAssertEqual(WhisperModel.base.speedRating, 4)
        XCTAssertEqual(WhisperModel.small.speedRating, 3)
        XCTAssertEqual(WhisperModel.medium.speedRating, 2)
        XCTAssertEqual(WhisperModel.large.speedRating, 1)
        XCTAssertEqual(WhisperModel.largeTurbo.speedRating, 3)
    }

    func testSpeedRatingsInRange() {
        for model in WhisperModel.allCases {
            XCTAssertGreaterThanOrEqual(model.speedRating, 1)
            XCTAssertLessThanOrEqual(model.speedRating, 5)
        }
    }

    // MARK: - Accuracy Ratings

    func testAccuracyRatings() {
        XCTAssertEqual(WhisperModel.tiny.accuracyRating, 1)
        XCTAssertEqual(WhisperModel.base.accuracyRating, 2)
        XCTAssertEqual(WhisperModel.small.accuracyRating, 3)
        XCTAssertEqual(WhisperModel.medium.accuracyRating, 4)
        XCTAssertEqual(WhisperModel.large.accuracyRating, 5)
        XCTAssertEqual(WhisperModel.largeTurbo.accuracyRating, 5)
    }

    func testAccuracyRatingsInRange() {
        for model in WhisperModel.allCases {
            XCTAssertGreaterThanOrEqual(model.accuracyRating, 1)
            XCTAssertLessThanOrEqual(model.accuracyRating, 5)
        }
    }

    // MARK: - Codable

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for model in WhisperModel.allCases {
            let encoded = try encoder.encode(model)
            let decoded = try decoder.decode(WhisperModel.self, from: encoded)
            XCTAssertEqual(model, decoded)
        }
    }

    func testCodableAsString() throws {
        let encoder = JSONEncoder()

        let encoded = try encoder.encode(WhisperModel.base)
        let jsonString = String(data: encoded, encoding: .utf8)

        // Raw value should be encoded as a string
        XCTAssertEqual(jsonString, "\"openai_whisper-base\"")
    }
}
