//
//  CacheService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

final class CacheService {
    static let shared = CacheService()

    private var storage: [String: CacheEntry] = [:]

    func get<T>(_ key: String) -> T? {
        guard let entry = storage[key] else { return nil }

        if let expiry = entry.expiresAt, expiry < Date() {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.value as? T
    }

    func set<T>(_ key: String, value: T, expiresIn: TimeInterval?) {
        let expiry = expiresIn.map { Date().addingTimeInterval($0) }
        storage[key] = CacheEntry(value: value, expiresAt: expiry)
    }
}

private struct CacheEntry {
    let value: Any
    let expiresAt: Date?
}
