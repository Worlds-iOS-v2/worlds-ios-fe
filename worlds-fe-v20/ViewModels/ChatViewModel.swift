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
    @Published var isSocketConnected = false
    
    private var currentRoomId: Int?
    private var messageListener: (() -> Void)?

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
    
    @Published var errorMessage: String?
    @Published var ocrList: [OCRList] = []

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
        print("🎬 [VM] connectAndJoin 시작 - roomId: \(chatId)")
        currentRoomId = chatId
        
        SocketService.shared.connect()
        SocketService.shared.joinRoom(roomId: chatId)
        
        // 🔥 중요: 메시지 리스너 설정
        setupMessageListener()
    }
    
    private func setupMessageListener() {
        print("🎧 [VM] 메시지 리스너 설정 중...")
        
        SocketService.shared.onReceiveMessage { [weak self] message in
            print("📩 [VM] 메시지 수신됨!")
            print("📩 [VM] 내용: \(message.content)")
            print("📩 [VM] 발신자: \(message.senderId)")
            print("📩 [VM] 방 ID: \(message.roomId)")
            
            guard let self = self else { return }
            
            // 🔥 중요: 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                print("🔄 [VM] UI 업데이트 시작...")
                
                // 중복 메시지 체크
                let exists = self.messages.contains { $0.id == message.id }
                if !exists {
                    self.messages.append(message)
                    print("✅ [VM] 메시지 추가 완료! 총 메시지 수: \(self.messages.count)")
                    
                    // 🔥 강제로 UI 업데이트 트리거
                    self.objectWillChange.send()
                } else {
                    print("⚠️ [VM] 중복 메시지 무시")
                }
            }
            
            // 읽음 처리
            if let roomId = self.currentRoomId {
                self.markUnreadFromOthersAsRead(roomId: roomId)
            }
        }
    }
    
    func sendMessage(chatId: Int, userId: Int, content: String) {
        print("📤 [VM] 메시지 전송 시작: \(content)")
        
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
        
        // 즉시 로컬 UI 업데이트 (보낸 메시지)
        DispatchQueue.main.async {
            self.messages.append(message)
            print("✅ [VM] 보낸 메시지 로컬 추가 완료")
        }
        
        // 서버로 전송
        SocketService.shared.sendMessage(message)
        print("📤 [VM] 서버로 메시지 전송 완료")
    }

    /// 이미지 전송 (낙관적 렌더링): 즉시 말풍선 추가 → 백그라운드 업로드 → URL 수신 후 소켓 전송
    func sendImage(chatId: Int, userId: Int, imageData: Data, mimeType: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = formatter.string(from: Date())
        
        // 1) 🔥 즉시 Base64 이미지로 표시
        let tempId = self.nextTempId()
        let base64String = "data:\(mimeType);base64,\(imageData.base64EncodedString())"
        
        let tempMessage = Message(
            id: tempId,
            roomId: chatId,
            senderId: userId,
            content: "",
            isRead: false,
            createdAt: createdAt,
            fileUrl: base64String, // Base64 URL
            fileType: mimeType
        )
        
        // 즉시 UI 업데이트
        DispatchQueue.main.async {
            self.messages.append(tempMessage)
            self.objectWillChange.send()
        }
        
        // 2) 🔥 백그라운드에서 압축 + 업로드
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // 압축 (필요한 경우)
            let finalData: Data
            if mimeType == "image/jpeg", imageData.count > 1024 * 1024 { // 1MB 이상인 경우만 압축
                if let image = UIImage(data: imageData),
                   let compressedData = image.jpegData(compressionQuality: 0.7) {
                    finalData = compressedData
                } else {
                    finalData = imageData
                }
            } else {
                finalData = imageData
            }
            
            SocketService.shared.uploadAttachment(
                data: finalData,
                fileName: "photo_\(Int(Date().timeIntervalSince1970)).jpg",
                mimeType: mimeType
            ) { [weak self] urlString in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let urlString = urlString {
                        // 🔥 성공: Base64를 실제 URL로 교체
                        if let index = self.messages.firstIndex(where: { $0.id == tempId }) {
                            let updatedMessage = Message(
                                id: tempId,
                                roomId: chatId,
                                senderId: userId,
                                content: "",
                                isRead: false,
                                createdAt: createdAt,
                                fileUrl: urlString, // 실제 서버 URL
                                fileType: mimeType
                            )
                            self.messages[index] = updatedMessage
                            
                            // 서버로 전송
                            SocketService.shared.sendMessage(updatedMessage)
                        }
                    } else {
                        // 🔥 실패: 임시 메시지 제거
                        if let index = self.messages.firstIndex(where: { $0.id == tempId }) {
                            self.messages.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    
    func disconnect() {
        print("👋 [VM] 소켓 연결 해제")
        SocketService.shared.disconnect()
        currentRoomId = nil
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
    
    @MainActor
    func fetchOCRList(userID: Int) async {        
        do {
            let ocrList = try await UserAPIManager.shared.getOCRList(userID: userID)
            self.ocrList = ocrList
            print("\(ocrList)")
            self.errorMessage = nil
        } catch {
            print("ocrList 에러 발생:", error)
            self.errorMessage = "OCR 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    func clearMessages() {
        messages.removeAll()
        objectWillChange.send()
    }
}
