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

    /// Legacy method retained for compatibility.
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

    /// Preferred method for storing full APIResponse envelope.
    func set(key: String, response: APIResponse<some Encodable>, expiresIn: TimeInterval?) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601WithFractionalSeconds
            let encodedResponse = try encoder.encode(response)
            let statusCode = response.statusCode

            queue.async {
                let expiry = expiresIn.map { Date().addingTimeInterval($0) }
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
                    self.log.error("Failed to write full APIResponse cache entry to disk")
                }
            }
        } catch {
            log.error("Failed to encode response for cache: \(error.localizedDescription)")
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
        let decoder = makeDecoder()

        // Try decoding the full APIResponse<T> envelope first
        if let response = try? decoder.decode(APIResponse<T>.self, from: entry.data) {
            return response
        }

        // Fallback: decode just T (legacy format), wrapping in APIResponse with stored statusCode
        if let body = try? decoder.decode(T.self, from: entry.data) {
            return APIResponse(statusCode: entry.statusCode, body: body)
        }

        log.error("Failed to decode cached entry")
        return nil
    }

    func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // First, attempt iso8601 with fractional seconds
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        // Wrap decode to fallback to iso8601 without fractional seconds if needed
        // We'll override decode to handle fallback internally:
        // But since we can't override decode, just return decoder here.
        // The fallback is implemented by trying decode twice in decode helper above.
        return decoder
    }
}

private nonisolated struct DiskCacheEntry: Codable {
    let data: Data
    let statusCode: Int
    let expiresAt: Date?
}

private extension JSONDecoder.DateDecodingStrategy {
    /// ISO8601 with fractional seconds, compatible with NetworkClient.decode
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            let formatterWithFractionalSeconds = ISO8601DateFormatter()
            formatterWithFractionalSeconds.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds,
            ]
            if let date = formatterWithFractionalSeconds.date(from: dateStr) {
                return date
            }
            let formatterWithoutFractionalSeconds = ISO8601DateFormatter()
            formatterWithoutFractionalSeconds.formatOptions = [
                .withInternetDateTime,
            ]
            if let date = formatterWithoutFractionalSeconds.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateStr)",
            )
        }
    }
}

private extension JSONEncoder.DateEncodingStrategy {
    /// ISO8601 with fractional seconds, compatible with NetworkClient.decode
    static var iso8601WithFractionalSeconds: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatterWithFractionalSeconds = ISO8601DateFormatter()
            formatterWithFractionalSeconds.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds,
            ]
            let string = formatterWithFractionalSeconds.string(from: date)
            try container.encode(string)
        }
    }
}
