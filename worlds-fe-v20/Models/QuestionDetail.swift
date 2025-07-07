//
//  QuestionDetail.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/7/25.
//

import Foundation

struct QuestionDetail: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let content: String
    let createdAt: String
//    let updatedAt: String?
    let deletedAt: String?
    let userId: Int
    let user: QuestionUser
    let category: Category
    let isAnswered: Bool
    let answerCount: Int
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
//        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case userId = "user_id"
        case user
        case category
        case isAnswered = "is_answered"
        case answerCount = "answer_count"
        case imageUrl = "image_url"
    }
}
