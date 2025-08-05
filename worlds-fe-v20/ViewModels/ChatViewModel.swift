//
//  ChatViewModel.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/4/25.
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    func connectAndJoin(chatId: Int) {
        SocketService.shared.connect()
        SocketService.shared.joinRoom(roomId: chatId)
        SocketService.shared.onReceiveMessage { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
            }
        }
    }

    func sendMessage(chatId: Int, userId: String, content: String) {
        let message = Message(
            id: 0,
            roomId: chatId,
            senderId: Int(userId) ?? 0,
            content: content,
            isRead: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        SocketService.shared.sendMessage(message)
    }

    func disconnect() {
        SocketService.shared.disconnect()
    }
    
    func listenForMessageRead() {
        SocketService.shared.onMessageRead { [weak self] messageId in
            DispatchQueue.main.async {
                if let index = self?.messages.firstIndex(where: { $0.id == messageId }) {
                    self?.messages[index].isRead = true
                }
            }
        }
    }
}
