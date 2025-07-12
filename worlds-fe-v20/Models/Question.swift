//
//  Question.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
import Foundation

enum Category: String, Codable {
    case all = "전체 보기"
    case study = "학습 게시판"
    case free = "자유 게시판"
}

//질문 목록
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

//질문 작성자
struct QuestionUser: Codable, Hashable {
    let id: Int
    let name: String
    let email: String
    let role: String
    
    enum CoingKeys: String, CodingKey {
        case id
        case name = "user_name"
        case email = "user_email"
        case role = "user_role"
    }
}

//질문 생성 (->이미지 포함해야해서 뺌)
//struct CreateQuestion: Codable {
//    let title: String
//    let content: String
//    let category: String
//    let imageUrl: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case title
//        case content
//        case category
//        case imageUrl = "image_url"
//    }
//}
