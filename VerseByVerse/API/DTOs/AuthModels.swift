//
//  AuthModels.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 5/17/26.
//

// https://app.quicktype.io

import Foundation

struct PostLoginResponse: Codable {
    let accessToken, tokenType, refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
    }
}

struct PostRefreshResponse: Codable {
    let accessToken, refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
