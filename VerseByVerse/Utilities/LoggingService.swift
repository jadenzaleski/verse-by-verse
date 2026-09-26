//
//  LoggingService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

/// File I/O only, self-synchronized via its own background queue — safe to call
/// from any thread, so it opts out of the project's default MainActor isolation.
/// All stored properties are immutable and of `Sendable` types.
final nonisolated class LoggingService: Sendable {
    static let shared = LoggingService()
    private static let timestampFormatter = ISO8601DateFormatter()
    /// Filename-safe timestamp (no colons) for rotated and exported files.
    private static let fileTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private let queue = DispatchQueue(label: "LoggingQueue", qos: .background)
    private let maxFileSize: Int = 200_000 // 200 KB per file
    private let maxLogFiles: Int = 2 // 2 rotated + 1 active ≈ 600 KB max
    private let maxLogAge: TimeInterval = 7 * 24 * 3600 // 7 days
    private let logsDirectory: URL
    private var currentLogURL: URL {
        logsDirectory.appendingPathComponent("vbv.log")
    }

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        logsDirectory = caches.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
    }

    func log(level: LogLevel, category: String, source: String, message: String) {
        queue.async {
            let timestamp = Self.timestampFormatter.string(from: Date())
            let entry = "[\(timestamp)] [\(level.fileTag)] [\(category)] (\(source)) \(message)\n"
            self.rotateIfNeeded()
            self.appendToFile(entry)
        }
    }

    private func appendToFile(_ text: String) {
        let data = text.data(using: .utf8)!

        if FileManager.default.fileExists(atPath: currentLogURL.path) {
            if let handle = try? FileHandle(forWritingTo: currentLogURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: currentLogURL)
        }
    }

    private func rotateIfNeeded() {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: currentLogURL.path),
              let size = attributes[.size] as? NSNumber,
              size.intValue > maxFileSize else { return }

        let dateStr = Self.fileTimestampFormatter.string(from: Date())
        let rotatedURL = logsDirectory.appendingPathComponent("vbv_\(dateStr).log")

        try? FileManager.default.moveItem(at: currentLogURL, to: rotatedURL)
        cleanupOldLogs()
    }

    private func cleanupOldLogs() {
        let keys: [URLResourceKey] = [.creationDateKey]
        let files = (try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: keys,
        )) ?? []

        let cutoff = Date().addingTimeInterval(-maxLogAge)

        // Sort rotated files newest-first; skip the active vbv.log (handled separately).
        let rotated = files
            .filter { $0.lastPathComponent != "vbv.log" }
            .sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let rhsDate = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return lhsDate > rhsDate
            }

        for (index, file) in rotated.enumerated() {
            let created = (try? file.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            if index >= maxLogFiles || created < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    func readAllLogs() -> String {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: nil,
        )) ?? []
        // Rotated files use yyyyMMdd-HHmmss names, so ascending lexical sort = chronological.
        // Active file always goes last so the full log reads oldest → newest.
        let rotated = files.filter {
            $0.lastPathComponent != "vbv.log"
        }.sorted {
            $0.lastPathComponent < $1.lastPathComponent
        }
        let active = files.filter { $0.lastPathComponent == "vbv.log" }
        let ordered = rotated + active

        return ordered.compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined(separator: "\n-----\n")
    }

    /// Deletes all persisted log files (current and rotated).
    func clearLogs() {
        queue.async {
            let files = (
                try? FileManager.default.contentsOfDirectory(at: self.logsDirectory, includingPropertiesForKeys: nil),
            ) ?? []
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    /// Writes all logs (with a build/version header) to a single temporary file
    /// suitable for the share sheet, returning its URL. The file is named so it's
    /// recognizable when received via Mail/Messages/AirDrop/Files.
    func exportLogs() -> URL? {
        exportLogs(contents: readAllLogs())
    }

    /// Same as ``exportLogs()``, but reuses log contents the caller already read
    /// instead of hitting disk a second time.
    func exportLogs(contents: String) -> URL? {
        let header = """
        VerseByVerse Logs
        Version: \(AppFunctions.versionString() ?? "unknown")
        Channel: \(AppFunctions.channel)
        Exported: \(Self.timestampFormatter.string(from: Date()))

        """

        let fileName = "VerseByVerse-logs-\(Self.fileTimestampFormatter.string(from: Date())).log"
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try (header + contents).write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            return nil
        }
    }
}
