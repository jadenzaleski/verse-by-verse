//
//  AppAttestClient.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/24/26.
//

import CryptoKit
import DeviceCheck
import Foundation
import Observation

/// Proves to the Bible API that requests come from a genuine copy of the app
/// on real Apple hardware, and keeps a short-lived session token for them.
///
/// Lifecycle (see the server's `app/attest/`): generate a Secure Enclave key
/// once per install, attest it with Apple via `/attest/register`, then send
/// `Authorization: Bearer <token>`. When the token nears expiry (or the server
/// says it expired) an on-device assertion buys a new one via
/// `/attest/session` — Apple is contacted only to attest a new key.
///
/// It never throws and never blocks a request for long: `token()` returns
/// `nil` on unsupported devices (the Simulator), while backing off after a
/// failure, or if registration is slow, and the request simply goes out
/// unattested (public-domain text still works). **Never log tokens,
/// assertions, or attestations** — log `fingerprint(of:)` instead.
@MainActor
@Observable
final class AppAttestClient {
    static let shared = AppAttestClient(
        attest: SystemAppAttest(),
        store: KeychainAttestKeyStore(),
        server: APIAttestServer(),
    )

    /// Refresh this long before expiry so a request never races the cutoff.
    static let refreshMargin: TimeInterval = 5 * 60

    private let attest: AppAttesting
    private let store: AttestKeyStore
    private let server: AttestServer
    private let now: () -> Date
    private let log = AppLog.category("AppAttest")

    private var session: AttestSession?
    private var inFlight: Task<String?, Never>?
    private var retryAt: Date?
    private var backoff: TimeInterval = 0

    init(
        attest: AppAttesting,
        store: AttestKeyStore,
        server: AttestServer,
        now: @escaping () -> Date = Date.init,
    ) {
        self.attest = attest
        self.store = store
        self.server = server
        self.now = now
    }

    /// False on the Simulator and other devices without App Attest.
    var isSupported: Bool {
        attest.isSupported
    }

    /// True while this install holds an unexpired session token. Observable, so
    /// views update when registration or a refresh completes.
    var isAttested: Bool {
        guard let session else { return false }
        return session.expiresAt > now()
    }

    /// A short description for the Developer screen. Contains no secrets.
    var statusDescription: String {
        guard isSupported else { return "Unsupported on this device" }
        if isAttested {
            return "Attested (\(fingerprint(of: store.load()?.keyId)))"
        }
        if let retryAt, retryAt > now() {
            return "Retrying after a failure"
        }
        if store.load()?.registered == true {
            return "Registered, token expired"
        }
        return "Not registered yet"
    }

    /// A valid session token, registering or refreshing first if needed.
    /// Waits at most `timeout` for that work; it keeps running afterwards so
    /// the next request benefits.
    func token(timeout: Duration = .seconds(5)) async -> String? {
        guard attest.isSupported else { return nil }
        if let session, session.expiresAt.timeIntervalSince(now()) > Self.refreshMargin {
            return session.token
        }
        if inFlight == nil {
            if let retryAt, retryAt > now() {
                return nil
            }
            inFlight = Task { await self.obtainToken() }
        }
        guard let task = inFlight else { return nil }

        // Race the work against the timeout. Not a task group: a group waits
        // for every child, and `task.value` can't be cancelled, so the
        // timeout would never cut the wait short.
        return await withCheckedContinuation { continuation in
            let race = FirstResult(continuation)
            let timer = Task {
                try? await Task.sleep(for: timeout)
                race.resume(with: nil)
            }
            Task {
                await race.resume(with: task.value)
                timer.cancel()
            }
        }
    }

    /// Drops the cached token after the server rejected it (expired or
    /// invalid), so the next `token()` refreshes with an assertion.
    func invalidateToken() {
        session = nil
    }

    // MARK: - Flow

    private func obtainToken() async -> String? {
        defer { inFlight = nil }
        do {
            let session = try await establishSession()
            self.session = session
            retryAt = nil
            backoff = 0
            return session.token
        } catch {
            recordFailure(error)
            return nil
        }
    }

    private func establishSession() async throws -> AttestSession {
        if let key = store.load() {
            if !key.registered {
                return try await register(key)
            }
            do {
                return try await refresh(key)
            } catch let error as AttestServerError where error.detail == "ATTEST_KEY_UNKNOWN" {
                log.warning("Server doesn't know key \(fingerprint(of: key.keyId)); registering a new one")
                store.clear()
            } catch let error as DCError where error.code == .invalidKey {
                // The Keychain survived a reinstall or restore; the Enclave key didn't.
                log.warning("Key \(fingerprint(of: key.keyId)) is no longer valid; registering a new one")
                store.clear()
            }
        }

        let keyId = try await attest.generateKey()
        let key = StoredAttestKey(keyId: keyId, registered: false)
        store.save(key)
        log.info("Generated App Attest key \(fingerprint(of: keyId))")
        return try await register(key)
    }

    private func register(_ key: StoredAttestKey) async throws -> AttestSession {
        let challenge = try await server.challenge()
        guard let challengeBytes = Data(base64Encoded: challenge) else {
            throw AttestServerError(status: 0, detail: "ATTEST_MALFORMED")
        }

        let attestation: Data
        do {
            attestation = try await attest.attestKey(
                key.keyId,
                clientDataHash: Data(SHA256.hash(data: challengeBytes)),
            )
        } catch let error as DCError where error.code == .serverUnavailable {
            throw error // Apple is busy: keep the key and retry it later.
        } catch {
            store.clear() // Any other attest failure means the key is unusable.
            throw error
        }

        let session: AttestSession
        do {
            session = try await server.register(keyId: key.keyId, attestation: attestation, challenge: challenge)
        } catch let error as AttestServerError where error.detail == "ATTEST_KEY_EXISTS" {
            // Registered on a previous attempt whose response never arrived.
            let registered = StoredAttestKey(keyId: key.keyId, registered: true)
            store.save(registered)
            return try await refresh(registered)
        } catch let error as AttestServerError where error.detail == "ATTEST_INVALID" {
            store.clear()
            throw error
        }

        store.save(StoredAttestKey(keyId: key.keyId, registered: true))
        log.info("Registered App Attest key \(fingerprint(of: key.keyId))")
        return session
    }

    private func refresh(_ key: StoredAttestKey) async throws -> AttestSession {
        let challenge = try await server.challenge()
        // The server verifies the signature over these exact bytes, then
        // parses them only to find the challenge — never re-encode them.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let clientData = try encoder.encode(["purpose": "session", "challenge": challenge])

        let assertion = try await attest.generateAssertion(
            key.keyId,
            clientDataHash: Data(SHA256.hash(data: clientData)),
        )
        return try await server.session(keyId: key.keyId, clientData: clientData, assertion: assertion)
    }

    private func recordFailure(_ error: Error) {
        // Exponential backoff (30 s → 1 h) so a persistent failure never
        // turns every verse fetch into an attestation attempt — and never
        // floods Apple's rate-limited attest service.
        backoff = min(max(backoff * 2, 30), 3600)
        retryAt = now() + backoff
        log.error("App Attest failed (\(Self.describe(error))); retrying in \(Int(backoff))s")
    }

    private static func describe(_ error: Error) -> String {
        switch error {
        case let error as AttestServerError: "server \(error.status) \(error.detail)"
        case let error as DCError: "DCError \(error.code.rawValue)"
        case let error as URLError: "network \(error.code.rawValue)"
        default: String(describing: type(of: error))
        }
    }

    /// Resumes a continuation with whichever result arrives first. Main-actor
    /// isolated like its callers, so the flag needs no lock.
    private final class FirstResult {
        private var continuation: CheckedContinuation<String?, Never>?

        init(_ continuation: CheckedContinuation<String?, Never>) {
            self.continuation = continuation
        }

        func resume(with value: String?) {
            continuation?.resume(returning: value)
            continuation = nil
        }
    }

    /// Short, non-reversible handle for logs.
    private func fingerprint(of keyId: String?) -> String {
        guard let keyId else { return "none" }
        return SHA256.hash(data: Data(keyId.utf8)).prefix(4).map { String(format: "%02x", $0) }.joined()
    }
}
