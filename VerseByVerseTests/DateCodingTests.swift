//
//  DateCodingTests.swift
//  VerseByVerseTests
//

import Foundation
import Testing
@testable import VerseByVerse

/// Pins the app-wide JSON date format: ISO-8601 in UTC, fractional seconds
/// on the way out, either form accepted on the way in.
struct DateCodingTests {
    private struct Box: Codable, Equatable {
        let date: Date
    }

    // 2026-01-01T12:00:00.250Z
    private let moment = Date(timeIntervalSince1970: 1_767_268_800.25)

    @Test func `encodes ISO-8601 UTC with milliseconds`() throws {
        let data = try JSONEncoder.vbv.encode(Box(date: moment))
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("2026-01-01T12:00:00.250Z"), "got \(json)")
    }

    @Test func `decodes with fractional seconds`() throws {
        let json = Data(#"{"date":"2026-01-01T12:00:00.250Z"}"#.utf8)
        let box = try JSONDecoder.vbv.decode(Box.self, from: json)
        #expect(abs(box.date.timeIntervalSince(moment)) < 0.001)
    }

    @Test func `decodes without fractional seconds`() throws {
        let json = Data(#"{"date":"2026-01-01T12:00:00Z"}"#.utf8)
        let box = try JSONDecoder.vbv.decode(Box.self, from: json)
        #expect(box.date == Date(timeIntervalSince1970: 1_767_268_800))
    }

    @Test func `round trips`() throws {
        let data = try JSONEncoder.vbv.encode(Box(date: moment))
        let box = try JSONDecoder.vbv.decode(Box.self, from: data)
        #expect(abs(box.date.timeIntervalSince(moment)) < 0.001)
    }

    /// Millisecond values that aren't exactly representable as a `Double` used
    /// to drift by 1 ms per round trip (the format style truncates). Cover many.
    @Test func `round trips stay stable across many millisecond values`() throws {
        for step in 0 ..< 2000 {
            let date = Date(timeIntervalSince1970: 1_767_268_800 + Double(step) * 0.001 + Double(step % 7) * 1e-5)
            let first = try JSONEncoder.vbv.encode(Box(date: date))
            let decoded = try JSONDecoder.vbv.decode(Box.self, from: first)
            let second = try JSONEncoder.vbv.encode(decoded)
            #expect(first == second, "step \(step): \(String(data: first, encoding: .utf8) ?? "")")
        }
    }

    @Test func `rounds to the nearest millisecond`() throws {
        let date = Date(timeIntervalSince1970: 1_767_268_800.1239)
        let json = try #require(String(data: JSONEncoder.vbv.encode(Box(date: date)), encoding: .utf8))
        #expect(json.contains("2026-01-01T12:00:00.124Z"), "got \(json)")
    }

    @Test func `pads short fractions and carries into the next second`() throws {
        let tiny = Date(timeIntervalSince1970: 1_767_268_800.004)
        let carry = Date(timeIntervalSince1970: 1_767_268_800.9996)
        let tinyJSON = try #require(String(data: JSONEncoder.vbv.encode(Box(date: tiny)), encoding: .utf8))
        let carryJSON = try #require(String(data: JSONEncoder.vbv.encode(Box(date: carry)), encoding: .utf8))
        #expect(tinyJSON.contains("2026-01-01T12:00:00.004Z"), "got \(tinyJSON)")
        #expect(carryJSON.contains("2026-01-01T12:00:01.000Z"), "got \(carryJSON)")
    }

    @Test func `rejects a malformed date`() {
        let json = Data(#"{"date":"yesterday"}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder.vbv.decode(Box.self, from: json)
        }
    }
}
