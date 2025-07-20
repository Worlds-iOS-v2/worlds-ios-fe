//
//  Comment.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 7/20/25.
//

import Foundation

struct Comment: Codable, Identifiable {
    let id: Int
    let content: String
    let createdAt: String
    let questionId: Int
    let user: User
    let parentId: Int?
    
    struct User: Codable {
        let id: Int
        let userName: String
        let isMentor: Bool
    }
}

struct CommentLike: Codable, Identifiable {
    let id: Int
    var count: Int
    var isLiked: Bool
}
