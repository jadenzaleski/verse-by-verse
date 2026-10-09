//
//  DataState.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

enum DataState: Equatable {
    case idle
    case loading
    case success
    case error(APIError)

    /// The failure, when in `.error`.
    var apiError: APIError? {
        guard case let .error(error) = self else { return nil }
        return error
    }

    static func == (lhs: DataState, rhs: DataState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            true
        case (.error, .error):
            // Consider all error states equal regardless of underlying APIError
            true
        default:
            false
        }
    }
}
