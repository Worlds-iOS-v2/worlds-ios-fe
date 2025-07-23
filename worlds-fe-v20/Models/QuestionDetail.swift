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
    let userId: Int
    let user: QuestionUser
    let category: Category
    let isAnswered: Bool
    let answerCount: Int
    let imageUrl: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "createdAt"
        case userId = "user_id"
        case user
        case category
        case isAnswered = "isAnswered"
        case answerCount = "answerCount"
        case imageUrl = "image_urls"
    }
}
