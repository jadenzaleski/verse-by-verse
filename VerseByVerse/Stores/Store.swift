//
//  Store.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.

import Foundation
import os

protocol Store: AnyObject {
    var state: DataState { get set }
    var lastError: APIError? { get set }

    func resetStateAndError()
    func clearError()
    func handle(error: Error)
}

extension Store {
    /// Default logger for any store implementation
    var log: Logger {
        AppLog.category(String(describing: self))
    }

    /// Default reset behavior
    func resetStateAndError() {
        state = .idle
        lastError = nil
    }

    /// Standardized error handling for all stores
    func handle(error: Error) {
        if let apiError = error as? APIError {
            lastError = apiError
            state = .error(apiError)
            log.error("API Error: \(apiError.localizedDescription)")
        } else {
            let unknown = APIError.unknown(underlying: error)
            lastError = unknown
            state = .error(unknown)
            log.error("Unknown Error: \(error.localizedDescription)")
        }
    }

    func clearError() {
        lastError = nil
    }
}
