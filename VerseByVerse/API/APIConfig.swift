//
//  APIConfig.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

/// This class is used to hold configuration for the ``APIEndpoint`` and its ``request`` function.
final class APIConfig {
    static let shared = APIConfig()

    let urls = [
        "https://vbv-api-dev.jadenzaleski.com",
        "http://127.0.0.1:8000",
    ]

    lazy var baseURL: URL = .init(string: urls[0])!

    private init() {}
}
