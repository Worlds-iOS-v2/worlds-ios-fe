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

    // 날짜별로 메시지 그룹화
    var groupedMessages: [String: [Message]] {
        let grouped = Dictionary(grouping: messages) { message in
            formatDateOnly(from: message.createdAt)
        }
        return grouped.mapValues { group in
            group.sorted(by: { $0.createdAt < $1.createdAt })
        }
    }

    private func formatDateOnly(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "ko_KR")
            displayFormatter.dateFormat = "yyyy년 M월 d일 EEEE"
            return displayFormatter.string(from: date)
        }
        return ""
    }
    
    func connectAndJoin(chatId: Int) {
        SocketService.shared.connect()
        SocketService.shared.joinRoom(roomId: chatId)
        SocketService.shared.onReceiveMessage { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
            }
        }
    }
    
    func sendMessage(chatId: Int, userId: Int, content: String) {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowString = formatter.string(from: now)

        let message = Message(
            id: UUID().hashValue, // 임시 ID
            roomId: chatId,
            senderId: userId,
            content: content,
            isRead: false,
            createdAt: nowString
        )

        // 서버로 전송
        SocketService.shared.sendMessage(message)

        // 즉시 로컬 반영
        DispatchQueue.main.async {
            self.messages.append(message)
        }
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
    
    func onReceiveMessage() {
        SocketService.shared.onReceiveMessage { [weak self] message in
            print("📩 onReceiveMessage 수신됨: \(message.content)")
            DispatchQueue.main.async {
                self?.messages.append(message)
            }
        }
    }
    
    func fetchMessages(for roomId: Int) {
        SocketService.shared.fetchMessages(roomId: roomId) { messagesArray in
            guard let messagesArray = messagesArray else { return }
            
            DispatchQueue.main.async {
                self.messages = messagesArray.compactMap { dict in
                    if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                       let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
                        return message
                    }
                    return nil
                }
            }
        }
    }
}
