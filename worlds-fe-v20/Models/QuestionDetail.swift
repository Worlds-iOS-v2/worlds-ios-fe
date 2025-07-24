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
    let user: QuestionUser
    let category: Category
    let answerCount: Int
    let imageUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "createdAt"
        case user
        case category
        case answerCount = "answerCount"
        case imageUrls = "attachments"
    }
}
