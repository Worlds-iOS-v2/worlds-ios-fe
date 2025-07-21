//
//  APIResponse.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/21/25.
//

struct APIResponse: Codable {
    var statusCode: Int
    var message: String
    var accessToken: String?
    var refreshToken: String?
    var error: String?
    var userInfo: User?
    var userEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case error, statusCode, message, userInfo
    }
}
