//
//  UserService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func getUser(lookInCache: Bool = true, saveToCache: Bool = true) async throws -> UserResponse {
        log.debug("getUser called")

        do {
            let response: APIResponse<UserResponse> = try await fetch(
                endpoint: APIEndpoint.getUser,
                lookInCache: lookInCache,
                saveToCache: saveToCache,
            )

            log.debug(
                "getUser succeeded — statusCode: \(response.statusCode), id: \(response.body.id)",
            )

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("getUser failed, statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("getUser failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }

    func patchUser(firstName: String? = nil,
                   lastName: String? = nil,
                   email: String? = nil,
                   password: String? = nil) async throws -> UserResponse
    {
        log.debug("patchUser called")

        do {
            let response: APIResponse<UserResponse> = try await fetch(
                endpoint: APIEndpoint.patchUser(
                    firstName: firstName, lastName: lastName, email: email, password: password,
                ),
                lookInCache: false,
                saveToCache: false,
            )

            log.debug(
                "patchUser succeeded — statusCode: \(response.statusCode), id: \(response.body.id)",
            )

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("patchUser failed, statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("patchUser failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }
}
