//
//  RateLimitRetry.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/12/26.
//

import SwiftUI

/// Retries a fetch that the API throttled (HTTP 429), once the server's
/// `Retry-After` has passed. Other failures are left to the screen's own
/// Try Again button and `retryWhenOnline`.
enum RateLimitRetry {
    /// While the screen's current error is `.rateLimited`, waits that error's
    /// `retryAfter` and calls `perform` again. Each new 429 brings a fresh
    /// delay; the loop ends once the error clears, or when the wait is
    /// cancelled (the view went away).
    @MainActor
    static func run(
        currentError: () -> APIError?,
        sleep: (TimeInterval) async throws -> Void,
        perform: () async -> Void,
    ) async {
        while case let .rateLimited(retryAfter)? = currentError() {
            do {
                try await sleep(retryAfter)
            } catch {
                return
            }
            // The user may have retried by hand while we waited.
            guard case .rateLimited? = currentError() else { return }
            await perform()
        }
    }
}

extension View {
    /// Re-runs `action` after the server's `Retry-After` whenever `error`
    /// reports a 429, for screens blocked on a single fetch. `error` is a
    /// closure so the loop sees the screen's latest state, not a snapshot.
    func retryAfterRateLimit(
        error: @escaping @MainActor () -> APIError?,
        perform action: @escaping () async -> Void,
    ) -> some View {
        modifier(RetryAfterRateLimit(error: error, action: action))
    }
}

private struct RetryAfterRateLimit: ViewModifier {
    let error: @MainActor () -> APIError?
    let action: () async -> Void

    private var isRateLimited: Bool {
        if case .rateLimited? = error() {
            true
        } else {
            false
        }
    }

    func body(content: Content) -> some View {
        // Keyed on the Bool so the wait starts when a 429 appears and is
        // cancelled when it clears or the view goes away. The retry itself runs
        // in an unstructured task: it flips the screen to "loading", which
        // changes the id and cancels this task, and that must not cancel the
        // fetch it just started.
        content.task(id: isRateLimited) {
            await RateLimitRetry.run(
                currentError: error,
                sleep: { try await Task.sleep(for: .seconds($0)) },
                perform: { await Task { await action() }.value },
            )
        }
    }
}
