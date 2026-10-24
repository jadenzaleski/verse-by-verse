//
//  AppAttestClientTests.swift
//  VerseByVerseTests
//
//  Created by Jaden Zaleski on 10/24/26.
//

import CryptoKit
import DeviceCheck
import Foundation
import Testing
@testable import VerseByVerse

/// The App Attest client's lifecycle: register once, reuse the session token,
/// refresh it with an assertion, and recover from every failure without ever
/// blocking a request (no token just means the unattested tier).
@Suite("App Attest client")
@MainActor
struct AppAttestClientTests {
    // MARK: - Fakes

    final class FakeAttest: AppAttesting {
        var isSupported = true
        var generatedKeys = 0
        var attestCalls: [(keyId: String, clientDataHash: Data)] = []
        var assertionCalls: [(keyId: String, clientDataHash: Data)] = []
        var attestError: Error?
        var assertionError: Error?

        func generateKey() async throws -> String {
            generatedKeys += 1
            return "key-\(generatedKeys)"
        }

        func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
            attestCalls.append((keyId, clientDataHash))
            if let attestError {
                throw attestError
            }
            return Data("attestation-\(keyId)".utf8)
        }

        func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
            assertionCalls.append((keyId, clientDataHash))
            if let assertionError {
                throw assertionError
            }
            return Data("assertion-\(keyId)".utf8)
        }
    }

    final class FakeServer: AttestServer {
        var challenges = 0
        var registered: [String] = []
        var sessions: [(keyId: String, clientData: Data)] = []
        var registerError: Error?
        var sessionError: Error?
        var tokenLifetime: TimeInterval = 3600
        var now: () -> Date = Date.init
        /// Lets a test hold registration open to observe concurrent callers.
        var registerGate: (() async -> Void)?

        func challenge() async throws -> String {
            challenges += 1
            return Data("challenge-\(challenges)".utf8).base64EncodedString()
        }

        func register(keyId: String, attestation _: Data, challenge _: String) async throws -> AttestSession {
            await registerGate?()
            if let registerError {
                throw registerError
            }
            registered.append(keyId)
            return AttestSession(token: "token-register-\(keyId)", expiresAt: now() + tokenLifetime)
        }

        func session(keyId: String, clientData: Data, assertion _: Data) async throws -> AttestSession {
            if let sessionError {
                throw sessionError
            }
            sessions.append((keyId, clientData))
            return AttestSession(token: "token-session-\(sessions.count)", expiresAt: now() + tokenLifetime)
        }
    }

    final class MemoryKeyStore: AttestKeyStore {
        var key: StoredAttestKey?
        func load() -> StoredAttestKey? {
            key
        }

        func save(_ key: StoredAttestKey) {
            self.key = key
        }

        func clear() {
            key = nil
        }
    }

    final class Clock {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    struct Harness {
        let attest = FakeAttest()
        let server = FakeServer()
        let store = MemoryKeyStore()
        let clock = Clock()
        let client: AppAttestClient

        @MainActor init() {
            let clock = clock
            server.now = { clock.now }
            client = AppAttestClient(attest: attest, store: store, server: server, now: { clock.now })
        }
    }

    // MARK: - Registration

    @Test func `unsupported devices never touch the service and get no token`() async {
        let harness = Harness()
        harness.attest.isSupported = false

        #expect(await harness.client.token() == nil)
        #expect(harness.attest.generatedKeys == 0)
        #expect(harness.server.challenges == 0)
    }

    @Test func `first token registers a new key`() async throws {
        let harness = Harness()

        let token = await harness.client.token()

        #expect(token == "token-register-key-1")
        #expect(harness.server.registered == ["key-1"])
        #expect(harness.store.key == StoredAttestKey(keyId: "key-1", registered: true))
        // attestKey signs SHA256 of the decoded challenge bytes.
        let call = try #require(harness.attest.attestCalls.first)
        #expect(call.clientDataHash == Data(SHA256.hash(data: Data("challenge-1".utf8))))
    }

    @Test func `a valid token is reused without any network`() async {
        let harness = Harness()
        _ = await harness.client.token()

        let again = await harness.client.token()

        #expect(again == "token-register-key-1")
        #expect(harness.server.challenges == 1)
    }

    @Test func `concurrent callers share one registration`() async {
        let harness = Harness()
        var release: CheckedContinuation<Void, Never>?
        harness.server.registerGate = { await withCheckedContinuation { release = $0 } }

        async let first = harness.client.token()
        async let second = harness.client.token()
        while release == nil {
            await Task.yield()
        }
        release?.resume()

        let tokens = await [first, second]
        #expect(tokens == ["token-register-key-1", "token-register-key-1"])
        #expect(harness.attest.generatedKeys == 1)
        #expect(harness.server.registered.count == 1)
    }

    // MARK: - Refresh

    @Test func `a token near expiry is refreshed with an assertion`() async throws {
        let harness = Harness()
        _ = await harness.client.token()
        harness.clock.now += 3600 - 60 // inside the 5-minute refresh window

        let refreshed = await harness.client.token()

        #expect(refreshed == "token-session-1")
        let session = try #require(harness.server.sessions.first)
        #expect(session.keyId == "key-1")
        let payload = try JSONDecoder().decode([String: String].self, from: session.clientData)
        #expect(payload == ["purpose": "session", "challenge": Data("challenge-2".utf8).base64EncodedString()])
        // The assertion signs SHA256 of exactly the bytes sent to the server.
        #expect(harness.attest.assertionCalls.first?.clientDataHash == Data(SHA256.hash(data: session.clientData)))
    }

    @Test func `an invalidated token is refreshed on the next request`() async {
        let harness = Harness()
        _ = await harness.client.token()

        harness.client.invalidateToken()

        #expect(await harness.client.token() == "token-session-1")
    }

    @Test func `a stored registered key refreshes instead of re-registering`() async {
        let harness = Harness()
        harness.store.key = StoredAttestKey(keyId: "key-old", registered: true)

        #expect(await harness.client.token() == "token-session-1")
        #expect(harness.attest.generatedKeys == 0)
        #expect(harness.server.sessions.first?.keyId == "key-old")
    }

    // MARK: - Recovery

    @Test func `an unknown key on the server is replaced and re-registered`() async {
        let harness = Harness()
        harness.store.key = StoredAttestKey(keyId: "key-old", registered: true)
        harness.server.sessionError = AttestServerError(status: 401, detail: "ATTEST_KEY_UNKNOWN")

        let token = await harness.client.token()

        #expect(token == "token-register-key-1")
        #expect(harness.store.key == StoredAttestKey(keyId: "key-1", registered: true))
    }

    @Test func `an invalid key after a restore is replaced and re-registered`() async {
        let harness = Harness()
        harness.store.key = StoredAttestKey(keyId: "key-restored", registered: true)
        harness.attest.assertionError = DCError(.invalidKey)

        #expect(await harness.client.token() == "token-register-key-1")
        #expect(harness.store.key?.keyId == "key-1")
    }

    @Test func `server unavailable keeps the key and retries it later`() async {
        let harness = Harness()
        harness.attest.attestError = DCError(.serverUnavailable)

        #expect(await harness.client.token() == nil)
        #expect(harness.store.key == StoredAttestKey(keyId: "key-1", registered: false))

        harness.attest.attestError = nil
        harness.clock.now += 3600 // past any backoff
        #expect(await harness.client.token() == "token-register-key-1")
        #expect(harness.attest.generatedKeys == 1) // same key, attested again
    }

    @Test func `any other attest error discards the key`() async {
        let harness = Harness()
        harness.attest.attestError = DCError(.unknownSystemFailure)

        #expect(await harness.client.token() == nil)
        #expect(harness.store.key == nil)
    }

    @Test func `a rejected attestation discards the key`() async {
        let harness = Harness()
        harness.server.registerError = AttestServerError(status: 400, detail: "ATTEST_INVALID")

        #expect(await harness.client.token() == nil)
        #expect(harness.store.key == nil)
    }

    @Test func `an already registered key switches to a session refresh`() async {
        let harness = Harness()
        harness.store.key = StoredAttestKey(keyId: "key-old", registered: false)
        harness.server.registerError = AttestServerError(status: 409, detail: "ATTEST_KEY_EXISTS")

        #expect(await harness.client.token() == "token-session-1")
        #expect(harness.store.key == StoredAttestKey(keyId: "key-old", registered: true))
    }

    @Test func `failures back off instead of retrying every request`() async {
        let harness = Harness()
        harness.server.registerError = URLError(.notConnectedToInternet)

        #expect(await harness.client.token() == nil)
        let challengesAfterFailure = harness.server.challenges

        harness.server.registerError = nil
        #expect(await harness.client.token() == nil) // still backing off
        #expect(harness.server.challenges == challengesAfterFailure)

        harness.clock.now += 3600
        #expect(await harness.client.token() != nil)
    }

    @Test func `a slow registration times out to no token but keeps going`() async {
        let harness = Harness()
        var release: CheckedContinuation<Void, Never>?
        harness.server.registerGate = { await withCheckedContinuation { release = $0 } }

        #expect(await harness.client.token(timeout: .milliseconds(20)) == nil)

        release?.resume()
        #expect(await harness.client.token() == "token-register-key-1")
        #expect(harness.attest.generatedKeys == 1)
    }
}
