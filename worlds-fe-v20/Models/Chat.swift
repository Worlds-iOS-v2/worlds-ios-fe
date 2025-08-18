//
//  Chat.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/5/25.
//

import Foundation

// 실제 서버 채팅방 모델 (채팅 목록용)
struct ChatRoom: Identifiable, Codable {
    let id: Int
    let userAId: Int
    let userBId: Int
    let createdAt: String
    let userA: ChatUser
    let userB: ChatUser
    var messages: [Message]
    var unreadCount: Int?

    var name: String {
        return userB.userName
    }

    var preview: String {
        return messages.last?.content ?? ""
    }

    var dateString: String {
        return messages.last?.createdAt ?? ""
    }
}

struct ChatUser: Codable {
    let id: Int
    let userName: String
}

struct Message: Identifiable, Codable {
    let id: Int
    let roomId: Int
    let senderId: Int
    let content: String
    var isRead: Bool
    let createdAt: String
    
    let fileUrl: String?
    let fileType: String?

    var isSender: Bool {
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        return senderId == currentUserId
    }
}

// Message를 Equatable로 만들어서 중복 체크 가능하게 함
extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
