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

    static func category(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    static func logToFile(_ message: String) {
        LoggingService.shared.log(message)
    }
}

extension Logger {
    func log(_ message: String) {
        guard AppLog.minimumLevel <= .info else { return }
        let string = "\(message)"
        AppLog.logToFile("\(string)")
        log("\(message, privacy: .public)")
    }

    func trace(_ message: String) {
        guard AppLog.minimumLevel <= .trace else { return }
        let string = "\(message)"
        AppLog.logToFile("[TRACE] \(string)")
        trace("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        guard AppLog.minimumLevel <= .info else { return }
        let string = "\(message)"
        AppLog.logToFile("[INFO] \(string)")
        info("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        guard AppLog.minimumLevel <= .debug else { return }
        let string = "\(message)"
        AppLog.logToFile("[DEBUG] \(string)")
        debug("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        guard AppLog.minimumLevel <= .warning else { return }
        let string = "\(message)"
        AppLog.logToFile("[WARNING] \(string)")
        warning("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        guard AppLog.minimumLevel <= .error else { return }
        let string = "\(message)"
        AppLog.logToFile("[ERROR] \(string)")
        error("\(message, privacy: .public)")
    }

    func fault(_ message: String) {
        guard AppLog.minimumLevel <= .fault else { return }
        let string = "\(message)"
        AppLog.logToFile("[FAULT] \(string)")
        fault("\(message, privacy: .public)")
    }
}
