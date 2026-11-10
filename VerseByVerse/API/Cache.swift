//
//  Cache.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

/// Two-level (memory + disk) cache for Bible API responses.
///
/// An `actor`, so the in-memory layer and every disk read or write are
/// serialized without a lock and run off the main thread. Responses are
/// encoded and decoded on the caller's side (only `Data` crosses the actor
/// boundary), so response types need not be `Sendable`.
actor Cache {
    static let shared = Cache()

    private let log = AppLog.category("Cache")

    // L1: in-memory cache
    private var memory: [String: DiskCacheEntry] = [:]

    // L2: disk cache directory
    nonisolated let cacheDirectory: URL

    /// - Parameter directory: Where entries live on disk. Defaults to
    ///   `Caches/vbv-cache`; tests pass a temporary directory.
    init(directory: URL? = nil) {
        let dir = directory ?? {
            let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            return base.appending(path: "vbv-cache", directoryHint: .isDirectory)
        }()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        cacheDirectory = dir
    }
}

// MARK: - Public API

extension Cache {
    /// The cached response for `key`, if present and unexpired.
    nonisolated func get<T: Decodable>(_ key: String, decode _: T.Type) async -> APIResponse<T>? {
        guard let entry = await entry(for: key) else { return nil }
        return decode(entry, as: T.self)
    }

    /// Caches `response` under `key`. Returns once it is in memory and on disk.
    nonisolated func set(key: String, response: APIResponse<some Codable>, ttl: TimeInterval?) async {
        do {
            let encodedResponse = try JSONEncoder.vbv.encode(response)
            await store(key: key, data: encodedResponse, statusCode: response.statusCode, ttl: ttl)
        } catch {
            log.error("Failed to encode response for cache: \(error.localizedDescription)")
        }
    }

    /// Deletes every expired entry from memory and disk, plus any file that
    /// can't be read back as an entry.
    ///
    /// Entries without an expiry are kept. Returns how many files were removed.
    @discardableResult
    func purgeExpired(now: Date = Date()) -> Int {
        memory = memory.filter { !isExpired($0.value.expiresAt, at: now) }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil,
        )) ?? []

        var removed = 0
        for url in files {
            // Decode only the expiry; the (large) payload is skipped.
            let expiry = (try? Data(contentsOf: url))
                .flatMap { try? JSONDecoder().decode(EntryExpiry.self, from: $0) }
            let shouldRemove = expiry.map { isExpired($0.expiresAt, at: now) } ?? true
            if shouldRemove, (try? FileManager.default.removeItem(at: url)) != nil {
                removed += 1
            }
        }
        if removed > 0 {
            log.info("Purged \(removed) expired cache entries")
        }
        return removed
    }

    func removeAll() {
        memory.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
        )
    }
}

// MARK: - Actor-isolated storage

private extension Cache {
    /// Memory first, then disk; drops an expired entry it finds.
    func entry(for key: String) -> DiskCacheEntry? {
        // 1. Memory
        if let entry = memory[key] {
            if isExpired(entry) {
                memory.removeValue(forKey: key)
            } else {
                return entry
            }
        }

        // 2. Disk
        let url = fileURL(for: key)
        guard
            let data = try? Data(contentsOf: url),
            let entry = try? JSONDecoder().decode(DiskCacheEntry.self, from: data)
        else {
            return nil
        }

        if isExpired(entry) {
            try? FileManager.default.removeItem(at: url)
            return nil
        }

        memory[key] = entry
        return entry
    }

    func store(key: String, data: Data, statusCode: Int, ttl: TimeInterval?) {
        let expiry = ttl.map { Date().addingTimeInterval($0) }
        let entry = DiskCacheEntry(data: data, statusCode: statusCode, expiresAt: expiry)

        memory[key] = entry

        do {
            let encodedEntry = try JSONEncoder().encode(entry)
            try encodedEntry.write(to: fileURL(for: key), options: .atomic)
        } catch {
            log.error("Failed to write cache entry to disk")
        }
    }
}

// MARK: - Helpers

private extension Cache {
    nonisolated func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent(safeKey)
    }

    nonisolated func isExpired(_ entry: DiskCacheEntry) -> Bool {
        isExpired(entry.expiresAt, at: Date())
    }

    nonisolated func isExpired(_ expiresAt: Date?, at now: Date) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt < now
    }

    nonisolated func decode<T: Decodable>(_ entry: DiskCacheEntry, as _: T.Type) -> APIResponse<T>? {
        if let response = try? JSONDecoder.vbv.decode(APIResponse<T>.self, from: entry.data) {
            return response
        }
        log.error("Failed to decode cached entry")
        return nil
    }
}

private nonisolated struct DiskCacheEntry: Codable, Sendable {
    let data: Data
    let statusCode: Int
    let expiresAt: Date?
}

/// Just the expiry of a ``DiskCacheEntry``, so purging doesn't decode payloads.
private nonisolated struct EntryExpiry: Decodable {
    let expiresAt: Date?
}
