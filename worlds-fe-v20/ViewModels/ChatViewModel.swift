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
            let dateKey = formatDateOnly(from: message.createdAt)
            return dateKey.isEmpty ? "unknown date" : dateKey
        }
        return grouped.mapValues { group in
            group.sorted { 
                guard let date0 = parseISO8601($0.createdAt), let date1 = parseISO8601($1.createdAt) else {
                    return $0.createdAt < $1.createdAt
                }
                return date0 < date1
            }
        }
    }

    private let pageSize = 20
    private var latestPageSkip: Int = 0
    private var discoveredTotal: Int?

    private func parseISO8601(_ s: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: s) {
            return date
        }
        // fallback without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: s)
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
        // 리스너 등록 (로그 포함)
        onReceiveMessage()
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

    func seed(initialMessages: [Message]) {
        DispatchQueue.main.async {
            let existingIDs = Set(self.messages.map { $0.id })
            let newMessages = initialMessages.filter { !existingIDs.contains($0.id) }
            self.messages.append(contentsOf: newMessages)
            self.messages.sort {
                guard let d0 = self.parseISO8601($0.createdAt), let d1 = self.parseISO8601($1.createdAt) else {
                    return $0.createdAt < $1.createdAt
                }
                return d0 < d1
            }
        }
    }

    func findLastPage(roomId: Int, completion: @escaping (Int) -> Void) {
        var skip = 0
        func fetchPage() {
            SocketService.shared.fetchMessages(roomId: roomId, take: pageSize, skip: skip) { messagesArray in
                guard let messagesArray = messagesArray else {
                    completion(skip)
                    return
                }
                if messagesArray.count < self.pageSize {
                    completion(skip)
                } else {
                    skip += self.pageSize
                    fetchPage()
                }
            }
        }
        fetchPage()
    }

    func loadLatestFirst(roomId: Int) {
        findLastPage(roomId: roomId) { lastSkip in
            DispatchQueue.main.async {
                self.discoveredTotal = lastSkip + self.pageSize
                self.latestPageSkip = lastSkip
                self.fetchMessages(roomId: roomId, take: self.pageSize, skip: lastSkip) {
                    // Optionally fetch previous page for context
                    if lastSkip > 0 {
                        let prevSkip = max(0, lastSkip - self.pageSize)
                        self.fetchMessages(roomId: roomId, take: self.pageSize, skip: prevSkip, prepend: true)
                    }
                }
            }
        }
    }

    func loadOlder(roomId: Int) {
        guard let total = discoveredTotal else { return }
        let nextSkip = max(0, latestPageSkip - pageSize)
        if nextSkip < 0 || nextSkip == latestPageSkip {
            return
        }
        fetchMessages(roomId: roomId, take: pageSize, skip: nextSkip, prepend: true) {
            self.latestPageSkip = nextSkip
        }
    }

    func fetchMessages(for roomId: Int) {
        fetchMessages(roomId: roomId, take: pageSize, skip: 0)
    }

    private func fetchMessages(roomId: Int, take: Int, skip: Int, prepend: Bool = false, completion: (() -> Void)? = nil) {
        SocketService.shared.fetchMessages(roomId: roomId, take: take, skip: skip) { messagesArray in
            guard let messagesArray = messagesArray else {
                completion?()
                return
            }

            DispatchQueue.main.async {
                let newMessages = messagesArray.compactMap { dict in
                    if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                       let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
                        return message
                    }
                    return nil
                }
                .sorted {
                    guard let d0 = self.parseISO8601($0.createdAt), let d1 = self.parseISO8601($1.createdAt) else {
                        return $0.createdAt < $1.createdAt
                    }
                    return d0 < d1
                }

                let existingIDs = Set(self.messages.map { $0.id })
                let filteredNew = newMessages.filter { !existingIDs.contains($0.id) }

                if prepend {
                    self.messages = (filteredNew + self.messages).sorted {
                        guard let d0 = self.parseISO8601($0.createdAt), let d1 = self.parseISO8601($1.createdAt) else {
                            return $0.createdAt < $1.createdAt
                        }
                        return d0 < d1
                    }
                } else {
                    self.messages = (self.messages + filteredNew).sorted {
                        guard let d0 = self.parseISO8601($0.createdAt), let d1 = self.parseISO8601($1.createdAt) else {
                            return $0.createdAt < $1.createdAt
                        }
                        return d0 < d1
                    }
                }
                completion?()
            }
        }
    }
}
