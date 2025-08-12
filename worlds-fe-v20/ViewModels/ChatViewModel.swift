//
//  ChatViewModel.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/4/25.
//

import Foundation
import Combine
import UIKit

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    // 임시 음수 ID 시드 (서버 ID와 충돌 방지)
    private var tempIdSeed: Int = -1
    private func nextTempId() -> Int { defer { tempIdSeed -= 1 }; return tempIdSeed }

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
            id: self.nextTempId(),
            roomId: chatId,
            senderId: userId,
            content: content,
            isRead: false,
            createdAt: nowString,
            fileUrl: nil,
            fileType: nil
        )

        // 서버로 전송
        SocketService.shared.sendMessage(message)

        // 즉시 로컬 반영
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }

    /// 이미지 전송 (낙관적 렌더링): 즉시 말풍선 추가 → 백그라운드 업로드 → URL 수신 후 소켓 전송
    func sendImage(chatId: Int, userId: Int, image: UIImage) {
        // 공통 타임스탬프
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = formatter.string(from: Date())

        // 1) 즉시 임시 메시지 추가 (fileUrl 없음 → UI에서 업로드 중 표시)
        let tempId = self.nextTempId()
        let tempMessage = Message(
            id: tempId,
            roomId: chatId,
            senderId: userId,
            content: "",
            isRead: false,
            createdAt: createdAt,
            fileUrl: nil,
            fileType: "image/jpeg"
        )
        DispatchQueue.main.async {
            self.messages.append(tempMessage)
        }

        // 2) 백그라운드에서 압축 + 업로드 → URL 확보 후 소켓 전송
        Task.detached { [weak self] in
            guard let self = self else { return }

            // 압축 (품질: 0.75)
            guard let data = image.jpegData(compressionQuality: 0.75) else {
                print("❌ JPEG 변환 실패")
                // 실패 시 임시 말풍선 제거
                DispatchQueue.main.async {
                    if let idx = self.messages.firstIndex(where: { $0.id == tempId }) {
                        self.messages.remove(at: idx)
                    }
                }
                return
            }

            SocketService.shared.uploadAttachment(
                data: data,
                fileName: "photo_\(Int(Date().timeIntervalSince1970)).jpg",
                mimeType: "image/jpeg"
            ) { [weak self] urlString in
                guard let self = self else { return }
                guard let fileUrl = urlString else {
                    print("❌ 업로드 실패: fileUrl 없음")
                    // 실패 시 임시 말풍선 제거
                    DispatchQueue.main.async {
                        if let idx = self.messages.firstIndex(where: { $0.id == tempId }) {
                            self.messages.remove(at: idx)
                        }
                    }
                    return
                }

                // 3) 임시 메시지 업데이트 (fileUrl 채우기)
                DispatchQueue.main.async {
                    if let idx = self.messages.firstIndex(where: { $0.id == tempId }) {
                        let old = self.messages[idx]
                        let new = Message(
                            id: old.id,
                            roomId: old.roomId,
                            senderId: old.senderId,
                            content: old.content,
                            isRead: old.isRead,
                            createdAt: old.createdAt,
                            fileUrl: fileUrl,                 // <- 업로드된 URL
                            fileType: "image/jpeg"            // 필요하면 유지/세팅
                        )
                        self.messages[idx] = new
                        // 이어서 실제 소켓 전송
                        let outbound = new
                        SocketService.shared.sendMessage(outbound)
                    }
                }
            }
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
            self?.markUnreadFromOthersAsRead(roomId: message.roomId)
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
                    self.markUnreadFromOthersAsRead(roomId: roomId)
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
    /// 현재 로드된 메시지 중 내가 받은(unread) 것들을 읽음 처리
    func markUnreadFromOthersAsRead(roomId: Int) {
        let myId = UserDefaults.standard.integer(forKey: "userId")
        let unreadFromOthers = messages.filter { $0.roomId == roomId && $0.senderId != myId && $0.isRead == false }
        guard let lastId = unreadFromOthers.map({ $0.id }).max() else { return }
        SocketService.shared.emitMessageRead(roomId: roomId, messageId: lastId)
    }
}
