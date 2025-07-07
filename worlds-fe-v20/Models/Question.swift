//
//  Question.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
import Foundation

enum Category: String, Codable {
    case all
    case study
    case life
    case culture
}

struct QuestionList: Codable, Identifiable, Hashable {
    //답변 완료 유무?
    let id: Int
    let title: String
    let createdAt: String
    let isAnswered: Bool
    let answerCount: Int
    let category: Category
    let user: QuestionUser

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt = "created_at"
        case isAnswered = "is_answered"
        case answerCount = "answer_count"
        case category
        case user
    }
}

struct QuestionUser: Codable, Hashable {
    let id: Int
    let name: String
    let email: String
    let role: String
}
