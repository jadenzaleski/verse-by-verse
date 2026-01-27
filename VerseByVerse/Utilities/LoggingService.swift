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

    private let queue = DispatchQueue(label: "LoggingQueue", qos: .background)
    private let maxFileSize: Int = 512_000 // 500 KB
    private let maxLogFiles: Int = 5

    private let logsDirectory: URL
    private var currentLogURL: URL { logsDirectory.appendingPathComponent("vbv.log") }

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logsDirectory = docs.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
    }

    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(message)\n"

        queue.async {
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

        let dateStr = ISO8601DateFormatter().string(from: Date())
        let rotatedURL = logsDirectory.appendingPathComponent("vbv_\(dateStr).log")

        try? FileManager.default.moveItem(at: currentLogURL, to: rotatedURL)
        cleanupOldLogs()
    }

    private func cleanupOldLogs() {
        let files = (
            try? FileManager.default
                .contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey])
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
            try? FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
        ) ?? []
        let sorted = files.sorted { $0.lastPathComponent < $1.lastPathComponent }

        return sorted.compactMap { try? String(contentsOf: $0, encoding: .utf8) }.joined(separator: "\n-----\n")
    }
}
