//
//  Cache.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

final class Cache {
    static let shared = Cache()

    private let log = AppLog.category("Cache")
    private let queue = DispatchQueue(label: "Cache.queue")

    // L1: in-memory cache
    private var memory: [String: DiskCacheEntry] = [:]

    // L2: disk cache directory
    let cacheDirectory: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appending(path: "vbv-cache", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
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

    func set(
        key: String,
        data: Data,
        statusCode: Int,
        expiresIn: TimeInterval?,
    ) {
        queue.async {
            let expiry = expiresIn.map { Date().addingTimeInterval($0) }
            let entry = DiskCacheEntry(
                data: data,
                statusCode: statusCode,
                expiresAt: expiry,
            )

            self.memory[key] = entry

            let url = self.fileURL(for: key)
            do {
                let encoded = try JSONEncoder().encode(entry)
                try encoded.write(to: url, options: .atomic)
            } catch {
                self.log.error("Failed to write cache entry to disk")
            }
        }
    }

    func remove(_ key: String) {
        queue.async {
            self.memory.removeValue(forKey: key)
            try? FileManager.default.removeItem(at: self.fileURL(for: key))
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
        guard let expiresAt = entry.expiresAt else { return false }
        return expiresAt < Date()
    }

    func decode<T: Decodable>(_ entry: DiskCacheEntry, as _: T.Type) -> APIResponse<T>? {
        do {
            let body = try JSONDecoder().decode(T.self, from: entry.data)
            return APIResponse(statusCode: entry.statusCode, body: body)
        } catch {
            log.error("Failed to decode cached entry")
            return nil
        }
    }
}

private nonisolated struct DiskCacheEntry: Codable, Sendable {
    let data: Data
    let statusCode: Int
    let expiresAt: Date?
}
