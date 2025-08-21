//
//  Chat.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/5/25.
//

import Foundation

// 실제 서버 채팅방 모델 (채팅 목록용)
struct ChatRoom: Identifiable, Codable, Hashable {
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
    
    // 🔥 Hashable 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 🔥 Equatable 구현
    static func == (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ChatUser: Codable, Hashable {
    let id: Int
    let userName: String
}

struct Message: Identifiable, Codable, Hashable {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

struct UnhideResponse: Codable {
    let roomId: Int
    let unhiddenFor: String
    let alreadyVisible: Bool
}
