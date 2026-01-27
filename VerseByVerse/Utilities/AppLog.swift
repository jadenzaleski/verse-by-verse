//
//  AppLog.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import os

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum AppLog {
    static let subsystem = "com.jadenzaleski.vbv"

    // Global minimum log level; messages below this level are dropped
    static var minimumLevel: LogLevel = {
        #if DEBUG
            return .debug
        #else
            return .info
        #endif
    }()

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
