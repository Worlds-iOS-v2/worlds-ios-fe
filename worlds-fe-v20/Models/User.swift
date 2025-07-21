//
//  User.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/8/25.
//

import Foundation

struct User: Codable, Hashable, Identifiable {
    let id: Int
    let userName: String
    let birthday: Date
    let userEmail: String
    let isMentor: Bool
    let reportedCount: Int
    let menteeTranslations: [String?]
}
