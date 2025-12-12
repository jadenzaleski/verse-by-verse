//
//  NetworkClient.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 12/11/25.
//

import Foundation

final class NetworkClient {
    static let shared = NetworkClient()
    private let session: URLSession
    private let log = AppLog.category("NetworkClient")

    private init() {
        session = URLSession(configuration: .default)
        log.debug("URLSession initialized")
    }

    func send<T: Decodable>(_ request: URLRequest, decode: T.Type) async throws -> APIResponse<T> {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.httpStatus(0)
        }

        let decodedBody = try JSONDecoder().decode(T.self, from: data)

        if !(200..<300).contains(http.statusCode) {
            throw NetworkError.httpStatus(http.statusCode)
        }

        return APIResponse(statusCode: http.statusCode, body: decodedBody)
    }
}

struct APIResponse<T: Decodable> {
    let statusCode: Int
    let body: T
}

enum NetworkError: Error {
    case httpStatus(Int)
}
