//
//  User.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/8/25.
//

import Foundation

struct User: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let birthDate: Date
    let email: String
    let password: String
    let role: UserRole
    let roleGrade: RoleGrade?
    let reportedCount: Int
    let point: Int
    let koreanGrade: KoreanGrade?
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "user_name"
        case birthDate = "user_birth_date"
        case email = "user_email"
        case password = "user_password_hash"
        case role = "user_role"
        case roleGrade = "user_role_grade"
        case reportedCount = "user_reported_count"
        case point = "user_point"
        case koreanGrade = "user_korean_grade"
        case refreshToken = "user_refresh_token"
    }
}
