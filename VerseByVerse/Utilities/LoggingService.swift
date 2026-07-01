//
//  LoggingService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation
import SwiftUI

final class LoggingService {
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
    private let maxFileSize: Int = 512_000 // 500 KB
    private let maxLogFiles: Int = 5
    private let logsDirectory: URL
    private var currentLogURL: URL {
        logsDirectory.appendingPathComponent("vbv.log")
    }

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
        let files = (
            try? FileManager.default
                .contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey]),
        ) ?? []

        let sorted = files.sorted {
            let aFile = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let bFile = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return aFile > bFile
        }

        let excess = sorted.dropFirst(maxLogFiles)
        for file in excess {
            try? FileManager.default.removeItem(at: file)
        }
    }

    func readAllLogs() -> String {
        let files = (
            try? FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil),
        ) ?? []
        let sorted = files.sorted { $0.lastPathComponent < $1.lastPathComponent }

        return sorted.compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined(separator: "\n-----\n")
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
        let header = """
        VerseByVerse Logs
        Version: \(AppFunctions.versionString() ?? "unknown")
        Channel: \(AppFunctions.channel)
        Exported: \(Self.timestampFormatter.string(from: Date()))

        """

        let fileName = "VerseByVerse-logs-\(Self.fileTimestampFormatter.string(from: Date())).log"
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try (header + readAllLogs()).write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            return nil
        }
    }
}
