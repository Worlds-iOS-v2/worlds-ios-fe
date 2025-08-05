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
    let messages: [Message]

    var name: String {
        return userB.userName // 예시. 본인이 userA이면 상대방 이름 반환
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
    let id: Int // 백 확인 필요~~
    let roomId: Int
    let senderId: Int
    let content: String
    var isRead: Bool
    let createdAt: String

    var isSender: Bool {
        // 나중에 ViewModel에서 현재 로그인 유저 ID와 비교 필요
        return false
    }
}
