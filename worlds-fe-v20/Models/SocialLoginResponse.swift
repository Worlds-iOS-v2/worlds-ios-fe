//
//  SocialLoginResponse.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

// 애플
struct AppleLoginResponse: Codable {
    let message: String
    let statusCode: Int
    let username: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case message, statusCode, username, profileImage
    }
}

// 카카오
struct KakaoLoginResponse: Codable {
    let message: String
    let statusCode: Int
    let userName: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case message, statusCode, userName, profileImage
    }
}
