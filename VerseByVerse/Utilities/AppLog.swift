//
//  AppLog.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation
import os

enum LogLevel: Int, Comparable, CaseIterable {
    case trace = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case fault = 5

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .trace: "Trace"
        case .debug: "Debug"
        case .info: "Info"
        case .warning: "Warning"
        case .error: "Error"
        case .fault: "Fault"
        }
    }

    /// Fixed-width tag written to the persisted log file so lines align and
    /// stay greppable (e.g. `[INFO ]`, `[ERROR]`).
    var fileTag: String {
        switch self {
        case .trace: "TRACE"
        case .debug: "DEBUG"
        case .info: "INFO "
        case .warning: "WARN "
        case .error: "ERROR"
        case .fault: "FAULT"
        }
    }
}

enum AppLog {
    static let subsystem = "com.jadenzaleski.vbv"

    /// Read the persisted minimum level from UserDefaults if present,
    /// otherwise provide a sensible default based on build configuration.
    private static var persistedMinimumLevel: LogLevel {
        if let raw = UserDefaults.standard.object(forKey: StorageKeys.logLevel.rawValue) as? Int,
           let level = LogLevel(rawValue: raw)
        {
            return level
        }
        #if DEBUG
            return .debug
        #else
            return .info
        #endif
    }

    static var minimumLevel: LogLevel = persistedMinimumLevel {
        didSet {
            UserDefaults.standard.set(minimumLevel.rawValue, forKey: StorageKeys.logLevel.rawValue)
        }
    }

    static func setMinimumLevel(_ level: LogLevel) {
        minimumLevel = level
    }

    /// Returns a category-scoped logger. The category is preserved in both the
    /// unified log (os.Logger) and the persisted, exportable log file.
    static func category(_ category: String) -> AppLogger {
        AppLogger(category: category)
    }
}

/// A category-scoped logger that mirrors each message to Apple's unified log
/// (`os.Logger`) and to the persisted, exportable log file via `LoggingService`.
///
/// - Important: Messages are recorded with `.public` privacy so they appear in
///   full in exported logs that testers send back. Never pass secrets (tokens,
///   passwords, raw request bodies) into these methods.
struct AppLogger {
    let category: String
    private let logger: Logger

    init(category: String) {
        self.category = category
        logger = Logger(subsystem: AppLog.subsystem, category: category)
    }

    func trace(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.trace, message, file: file, line: line)
    }

    func debug(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.debug, message, file: file, line: line)
    }

    func info(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.info, message, file: file, line: line)
    }

    func warning(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.warning, message, file: file, line: line)
    }

    func error(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.error, message, file: file, line: line)
    }

    func fault(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.fault, message, file: file, line: line)
    }

    /// Convenience alias for `info`, retained for existing call sites.
    func log(_ message: String, file: String = #fileID, line: Int = #line) {
        emit(.info, message, file: file, line: line)
    }

    private func emit(_ level: LogLevel, _ message: String, file: String, line: Int) {
        guard AppLog.minimumLevel <= level else { return }

        let source = "\(file):\(line)"
        LoggingService.shared.log(level: level, category: category, source: source, message: message)

        switch level {
        case .trace: logger.trace("\(message, privacy: .public)")
        case .debug: logger.debug("\(message, privacy: .public)")
        case .info: logger.info("\(message, privacy: .public)")
        case .warning: logger.warning("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        case .fault: logger.fault("\(message, privacy: .public)")
        }
    }
}
