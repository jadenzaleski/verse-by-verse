//
//  RateLimitRetryTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/12/26.
//

import Foundation
import Testing
@testable import VerseByVerse

/// 429 handling: the server's `Retry-After` becomes `APIError.rateLimited`,
/// and screens that block on a fetch retry once that delay has passed.
@Suite("Rate limit retry")
struct RateLimitRetryTests {
    // MARK: - Mapping

    private func response(retryAfter: String?) throws -> HTTPURLResponse {
        let url = try #require(URL(string: "https://example.com/bible"))
        let headers = retryAfter.map { ["Retry-After": $0] }
        return try #require(HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headers))
    }

    @Test func `retry-after seconds are read from the header`() throws {
        #expect(try APIError.retryAfter(from: response(retryAfter: "7")) == 7)
    }

    @Test func `missing retry-after falls back to a short default`() throws {
        #expect(try APIError.retryAfter(from: response(retryAfter: nil)) == 5)
    }

    @Test func `unparseable retry-after falls back to the default`() throws {
        #expect(try APIError.retryAfter(from: response(retryAfter: "soon")) == 5)
        #expect(try APIError.retryAfter(from: response(retryAfter: "Wed, 21 Oct 2026 07:28:00 GMT")) == 5)
    }

    @Test func `retry-after is clamped to one through sixty seconds`() throws {
        #expect(try APIError.retryAfter(from: response(retryAfter: "0")) == 1)
        #expect(try APIError.retryAfter(from: response(retryAfter: "-4")) == 1)
        #expect(try APIError.retryAfter(from: response(retryAfter: "600")) == 60)
    }

    @Test func `rate limited reads as busy, not as a raw status`() {
        let error = APIError.rateLimited(retryAfter: 12)

        #expect(error.localizedDescription == "The server is busy. Try again in a moment.")
        #expect(error.statusCode == 429)
    }

    @Test @MainActor func `rate limited says nothing about reachability`() {
        #expect(NetworkMonitor.classify(.rateLimited(retryAfter: 12)) == nil)
    }

    // MARK: - Retry loop

    /// Scripts what the screen's error is over time and records what the loop did.
    @MainActor
    private final class Scenario {
        var errors: [APIError?]
        var sleeps: [TimeInterval] = []
        var performs = 0
        /// Runs during each sleep, e.g. to simulate the user retrying by hand.
        var duringSleep: (() -> Void)?

        init(errors: [APIError?]) {
            self.errors = errors
        }

        /// The error as the screen currently sees it; the last entry sticks.
        var current: APIError? {
            errors.count > 1 ? errors[0] : errors.first ?? nil
        }

        func run(sleepThrows: Bool = false) async {
            await RateLimitRetry.run(
                currentError: { self.current },
                sleep: { seconds in
                    self.sleeps.append(seconds)
                    self.duringSleep?()
                    if sleepThrows {
                        throw CancellationError()
                    }
                },
                perform: {
                    self.performs += 1
                    if self.errors.count > 1 {
                        self.errors.removeFirst()
                    }
                },
            )
        }
    }

    @Test @MainActor func `waits the advised delay, then retries`() async {
        // Rate limited, then the retry succeeds.
        let scenario = Scenario(errors: [.rateLimited(retryAfter: 3), nil])
        await scenario.run()

        #expect(scenario.sleeps == [3])
        #expect(scenario.performs == 1)
    }

    @Test @MainActor func `keeps honoring each new retry-after while still limited`() async {
        let scenario = Scenario(errors: [
            .rateLimited(retryAfter: 3),
            .rateLimited(retryAfter: 2),
            .rateLimited(retryAfter: 5),
            nil,
        ])
        await scenario.run()

        #expect(scenario.sleeps == [3, 2, 5])
        #expect(scenario.performs == 3)
    }

    @Test @MainActor func `does nothing for other failures`() async {
        let scenario = Scenario(errors: [.http(statusCode: 502, message: nil, data: nil)])
        await scenario.run()

        #expect(scenario.sleeps.isEmpty)
        #expect(scenario.performs == 0)
    }

    @Test @MainActor func `skips the retry if the error cleared while waiting`() async {
        // The user tapped Try Again during the wait and it worked.
        let scenario = Scenario(errors: [.rateLimited(retryAfter: 3), nil])
        scenario.duringSleep = { scenario.errors = [nil] }
        await scenario.run()

        #expect(scenario.sleeps == [3])
        #expect(scenario.performs == 0)
    }

    @Test @MainActor func `a cancelled wait does not retry`() async {
        let scenario = Scenario(errors: [.rateLimited(retryAfter: 3)])
        await scenario.run(sleepThrows: true)

        #expect(scenario.performs == 0)
    }
}
