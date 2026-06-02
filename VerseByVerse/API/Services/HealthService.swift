//
//  HealthService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getHealth() async throws -> Bool {
        log.debug("getHealth called")
        do {
            let response: APIResponse<GetHealthResponse> = try await fetch(
                endpoint: APIEndpoint.getHealth,
                lookInCache: false,
                saveToCache: false,
            )

            return response.statusCode == 200 &&
                response.body.status == "ok" &&
                response.body.db == "ok" &&
                response.body.redis == "ok"
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("getHealth failed — statusCode: \(code), error: \(apiError.localizedDescription)")
            return false
        } catch {
            log.error("getHealth failed — unknown error: \(error.localizedDescription)")
            return false
        }
    }
}
