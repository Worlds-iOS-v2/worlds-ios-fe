//
//  User.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/8/25.
//

import Foundation

struct User: Codable, Hashable, Identifiable {
    let id: Int
    let userEmail: String
    let userName: String
    let birthday: String
    let isMentor: Bool
    let reportCount: Int
    let menteeTranslations: [MenteeTranslation]
}
