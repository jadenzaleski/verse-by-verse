//
//  KeychainManager.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/26/26.
//

import Foundation
import Security

enum KeychainManager {
    private static let log = AppLog.category("KeychainManager")
    private static let service = Bundle.main.bundleIdentifier ?? "vbv.keychain"
    private static let accessTokenKey = "access_token"
    private static let refreshTokenKey = "refresh_token"

    // MARK: - Public API

    static func saveAccessToken(_ token: String) throws {
        try save(token, for: accessTokenKey)
    }

    static func saveRefreshToken(_ token: String) throws {
        try save(token, for: refreshTokenKey)
    }

    static func getAccessToken() throws -> String? {
        try read(for: accessTokenKey)
    }

    static func getRefreshToken() throws -> String? {
        try read(for: refreshTokenKey)
    }

    static func updateAccessToken(_ token: String) throws {
        try update(token, for: accessTokenKey)
    }

    static func updateRefreshToken(_ token: String) throws {
        try update(token, for: refreshTokenKey)
    }

    static func deleteAccessToken() throws {
        try delete(for: accessTokenKey)
    }

    static func deleteRefreshToken() throws {
        try delete(for: refreshTokenKey)
    }

    static func clearAll() throws {
        try delete(for: accessTokenKey)
        try delete(for: refreshTokenKey)
    }

    // MARK: - Core CRUD

    private static func save(_ value: String, for key: String) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary) // overwrite if exists

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }

        log.info("Saved key: \(key)")
    }

    private static func read(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.unhandled(status)
        }

        log.info("Read key: \(key)")
        return value
    }

    private static func update(_ value: String, for key: String) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }

        log.info("Updated key: \(key)")
    }

    private static func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
        log.info("Deleted key: \(key)")
    }

    static func debugDump() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            log.debug("Keychain dump: no items found for service '\(service)'")
            return
        }

        guard status == errSecSuccess,
              let items = result as? [[String: Any]]
        else {
            log.error("Keychain dump failed: \(status)")
            return
        }

        log.debug("Keychain dump for service \(service):")

        for item in items {
            let account = item[kSecAttrAccount as String] as? String ?? "?"
            let data = item[kSecValueData as String] as? Data
            let value = data.flatMap { String(data: $0, encoding: .utf8) }

            log.debug("\(account): \(value ?? "nil")")
        }
    }
}

enum KeychainError: Error {
    case unhandled(OSStatus)
}
