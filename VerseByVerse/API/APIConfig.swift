//
//  APIConfig.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

final class APIConfig {
    static let shared = APIConfig()

    let urls = [
        "http://127.0.0.1:8000",
        "https://vbv-api-dev.jadenzaleski.com"
    ]

    lazy var baseURL: URL = URL(string: urls[0])!

    private init() {}
}
