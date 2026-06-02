//
//  AuthService.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

import Foundation

extension APIService {
    func postLogin(email: String, password: String) async throws -> PostLoginResponse {
        log.debug("postLogin called for email: \(email)")

        do {
            let response: APIResponse<PostLoginResponse> = try await fetch(
                endpoint: APIEndpoint.postLogin(email: email, password: password),
                lookInCache: false,
                saveToCache: false,
            )

            log.debug(
                "postLogin succeeded — statusCode: \(response.statusCode), tokenType: \(response.body.tokenType)",
            )

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("postLogin failed for email \(email) — statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("postLogin failed for email \(email) — unknown error: \(error.localizedDescription)")
            throw error
        }
    }

    func postRegister(firstName: String, lastName: String, email: String, password: String)
        async throws -> UserResponse
    {
        log.debug("postRegister called for email: \(email)")

        do {
            let response: APIResponse<UserResponse> = try await fetch(
                endpoint: APIEndpoint.postRegister(firstName: firstName,
                                                  lastName: lastName,
                                                  email: email,
                                                  password: password),
                lookInCache: false,
                saveToCache: false,
            )

            log.debug(
                "postRegister succeeded — statusCode: \(response.statusCode), id: \(response.body.id)",
            )

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("postRegister failed for email \(email) — statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("postRegister failed for email \(email) — unknown error: \(error.localizedDescription)")
            throw error
        }
    }

    func postRefresh(accessToken: String, refreshToken: String) async throws -> PostRefreshResponse {
        log.debug("postRefresh called")

        do {
            let response: APIResponse<PostRefreshResponse> = try await fetch(
                endpoint: APIEndpoint.postRefresh(accessToken: accessToken, refreshToken: refreshToken),
                lookInCache: false,
                saveToCache: false,
            )

            log.debug("postRefresh succeeded — statusCode: \(response.statusCode)")

            return response.body
        } catch let apiError as APIError {
            let code = apiError.statusCode.map(String.init) ?? "n/a"
            log.error("postRefresh failed, statusCode: \(code), " +
                "error: \(apiError.localizedDescription)")
            throw apiError
        } catch {
            log.error("postRefresh failed, unknown error: \(error.localizedDescription)")
            throw error
        }
    }
}
