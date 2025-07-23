//
//  Question.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
import Foundation

enum Category: String, Codable {
    case all = "all"
    case study = "study"
    case free = "free"
    
    var KoreanName: String {
            switch self {
            case .study: return "학습 게시판"
            case .free: return "자유 게시판"
            case .all: return "전체 게시판"
            }
        }
    }

//enum ReportReason: String, Codable {
//    case offensive
//    case sexual
//    case ad
//    case etc
//}
//
//extension ReportReason {
//    var displayName: String {
//        switch self {
//        case .offensive: return "비속어"
//        case .sexual: return "음란"
//        case .ad: return "광고"
//        case .etc: return "기타"
//        }
//    }
//}

//질문 목록
struct QuestionList: Codable, Identifiable, Hashable {
    //답변 완료 유무?
    let id: Int
    let title: String
    let content: String
    let createdAt: String
    let isAnswered: Bool
    let answerCount: Int
    let category: Category
    let user: QuestionUser

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content 
        case createdAt = "createdAt"
        case isAnswered = "isAnswered"
        case answerCount = "answerCount"
        case category
        case user
    }
}

//질문 작성자
struct QuestionUser: Codable, Hashable {
    let id: Int
    let name: String
    let email: String
    let role: Bool
    
    enum CodingKeys: String, CodingKey {
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
