//
//  Cache.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

/// Two-level (memory + disk) cache for Bible API responses.
final class Cache {
    static let shared = Cache()

    private let log = AppLog.category("Cache")
    private let queue = DispatchQueue(label: "Cache.queue")

    // L1: in-memory cache
    private var memory: [String: DiskCacheEntry] = [:]

    // L2: disk cache directory
    let cacheDirectory: URL

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
    func get<T: Decodable>(_ key: String, decode _: T.Type) -> APIResponse<T>? {
        queue.sync {
            // 1. Memory
            if let entry = memory[key] {
                if isExpired(entry) {
                    memory.removeValue(forKey: key)
                } else {
                    return decode(entry, as: T.self)
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
            return decode(entry, as: T.self)
        }
    }

    func set(key: String, response: APIResponse<some Encodable>, ttl: TimeInterval?) {
        do {
            let encodedResponse = try JSONEncoder.vbv.encode(response)
            let statusCode = response.statusCode

            queue.async {
                let expiry = ttl.map { Date().addingTimeInterval($0) }
                let entry = DiskCacheEntry(
                    data: encodedResponse,
                    statusCode: statusCode,
                    expiresAt: expiry,
                )

                self.memory[key] = entry

                let url = self.fileURL(for: key)
                do {
                    let encodedEntry = try JSONEncoder().encode(entry)
                    try encodedEntry.write(to: url, options: .atomic)
                } catch {
                    self.log.error("Failed to write cache entry to disk")
                }
            }
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
        queue.sync {
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
    }

    func removeAll() {
        queue.async {
            self.memory.removeAll()
            try? FileManager.default.removeItem(at: self.cacheDirectory)
            try? FileManager.default.createDirectory(
                at: self.cacheDirectory,
                withIntermediateDirectories: true,
            )
        }
    }
}

// MARK: - Helpers

private extension Cache {
    func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent(safeKey)
    }

    func isExpired(_ entry: DiskCacheEntry) -> Bool {
        isExpired(entry.expiresAt, at: Date())
    }

    func isExpired(_ expiresAt: Date?, at now: Date) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt < now
    }

    func decode<T: Decodable>(_ entry: DiskCacheEntry, as _: T.Type) -> APIResponse<T>? {
        if let response = try? JSONDecoder.vbv.decode(APIResponse<T>.self, from: entry.data) {
            return response
        }
        log.error("Failed to decode cached entry")
        return nil
    }
}

private nonisolated struct DiskCacheEntry: Codable {
    let data: Data
    let statusCode: Int
    let expiresAt: Date?
}

/// Just the expiry of a ``DiskCacheEntry``, so purging doesn't decode payloads.
private nonisolated struct EntryExpiry: Decodable {
    let expiresAt: Date?
}
