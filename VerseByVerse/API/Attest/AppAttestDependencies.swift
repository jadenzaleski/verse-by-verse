//
//  AppAttestDependencies.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 10/24/26.
//

import DeviceCheck
import Foundation
import Security

// The seams `AppAttestClient` is built on, each with its production
// implementation. Tests swap in fakes (see AppAttestClientTests).

// MARK: - DCAppAttestService

protocol AppAttesting {
    var isSupported: Bool { get }
    func generateKey() async throws -> String
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data
}

struct SystemAppAttest: AppAttesting {
    private var service: DCAppAttestService {
        .shared
    }

    var isSupported: Bool {
        service.isSupported
    }

    func generateKey() async throws -> String {
        try await service.generateKey()
    }

    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        try await service.attestKey(keyId, clientDataHash: clientDataHash)
    }

    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
    }
}

// MARK: - Key storage

/// The App Attest key handle. The private key itself never leaves the
/// Secure Enclave; `keyId` is only how the app refers to it.
struct StoredAttestKey: Codable, Equatable {
    let keyId: String
    /// True once the server accepted the attestation; until then the same
    /// key is attested again (e.g. after Apple returned `serverUnavailable`).
    var registered: Bool
}

protocol AttestKeyStore {
    func load() -> StoredAttestKey?
    func save(_ key: StoredAttestKey)
    func clear()
}

/// Keychain storage, this device only. It survives a reinstall even though
/// the Enclave key doesn't — `AppAttestClient` handles the resulting
/// `invalidKey` by registering a new key.
struct KeychainAttestKeyStore: AttestKeyStore {
    private let log = AppLog.category("AppAttest")

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.jadenzaleski.VerseByVerse.appattest",
            kSecAttrAccount as String: "key",
        ]
    }

    func load() -> StoredAttestKey? {
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(lookup as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return try? JSONDecoder().decode(StoredAttestKey.self, from: data)
    }

    func save(_ key: StoredAttestKey) {
        guard let data = try? JSONEncoder().encode(key) else { return }
        let update = [kSecValueData as String: data]
        var status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(item as CFDictionary, nil)
        }
        if status != errSecSuccess {
            log.error("Couldn't save App Attest key handle (OSStatus \(status))")
        }
    }

    func clear() {
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Server

/// A session token from `/attest/register` or `/attest/session`.
struct AttestSession: Equatable {
    let token: String
    let expiresAt: Date
}

/// The server refused an /attest call; `detail` is its `{"detail": ...}` code
/// (e.g. `ATTEST_KEY_UNKNOWN`, `ATTEST_INVALID`, `ATTEST_KEY_EXISTS`).
struct AttestServerError: Error, Equatable {
    let status: Int
    let detail: String
}

protocol AttestServer {
    func challenge() async throws -> String
    func register(keyId: String, attestation: Data, challenge: String) async throws -> AttestSession
    func session(keyId: String, clientData: Data, assertion: Data) async throws -> AttestSession
}

/// The real `/attest/*` routes. Uncached POSTs over the shared `NetworkClient`.
struct APIAttestServer: AttestServer {
    func challenge() async throws -> String {
        try await post("/attest/challenge", body: [:], as: AttestChallengeResponse.self).challenge
    }

    func register(keyId: String, attestation: Data, challenge: String) async throws -> AttestSession {
        try await session(from: post("/attest/register", body: [
            "key_id": keyId,
            "attestation": attestation.base64EncodedString(),
            "challenge": challenge,
        ], as: AttestTokenResponse.self))
    }

    func session(keyId: String, clientData: Data, assertion: Data) async throws -> AttestSession {
        try await session(from: post("/attest/session", body: [
            "key_id": keyId,
            "client_data": clientData.base64EncodedString(),
            "assertion": assertion.base64EncodedString(),
        ], as: AttestTokenResponse.self))
    }

    private func session(from response: AttestTokenResponse) -> AttestSession {
        AttestSession(token: response.token, expiresAt: Date(timeIntervalSince1970: response.expiresAt))
    }

    private func post<T: Decodable>(_ path: String, body: [String: String], as _: T.Type) async throws -> T {
        var request = URLRequest(url: AppFunctions.apiBaseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await NetworkClient.shared.raw(request)
        guard (200 ... 299).contains(response.statusCode) else {
            let detail = (try? JSONDecoder().decode(AttestErrorResponse.self, from: data))?.detail
            throw AttestServerError(
                status: response.statusCode,
                detail: detail ?? "HTTP_\(response.statusCode)",
            )
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - /attest wire format

private struct AttestChallengeResponse: Decodable {
    let challenge: String
}

private struct AttestTokenResponse: Decodable {
    let token: String
    let expiresAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }
}

private struct AttestErrorResponse: Decodable {
    let detail: String
}
