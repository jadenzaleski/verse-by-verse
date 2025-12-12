//
//  AppLog.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import os

struct AppLog {
    static let subsystem = "com.jadenzaleski.vbv"

    static func category(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    static func logToFile(_ message: String) {
        LoggingService.shared.log(message)
    }
}

extension Logger {
    func log(_ message: String) {
        let string = "\(message)"
        AppLog.logToFile("\(string)")
        self.log("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        let string = "\(message)"
        AppLog.logToFile("[INFO] \(string)")
        self.info("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        let string = "\(message)"
        AppLog.logToFile("[DEBUG] \(string)")
        self.debug("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        let string = "\(message)"
        AppLog.logToFile("[WARNING] \(string)")
        self.warning("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        let string = "\(message)"
        AppLog.logToFile("[ERROR] \(string)")
        self.error("\(message, privacy: .public)")
    }

    func fault(_ message: String) {
        let string = "\(message)"
        AppLog.logToFile("[FAULT] \(string)")
        self.fault("\(message, privacy: .public)")
    }
}
