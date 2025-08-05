//
//  SocketService.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/4/25.
//

import Foundation
import SocketIO

class SocketService {
    static let shared = SocketService()
    
    private var currentUserId: Int? {
        return UserDefaults.standard.value(forKey: "CurrentUserId") as? Int
    }
    
    private enum Event {
        static let joinRoom = "join_room"
        static let sendMessage = "send_message"
        static let receiveMessage = "receive_message"
        static let messageRead = "message_read"
    }
    
    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    private init() {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: urlString) else {
            fatalError("Invalid or missing 'APIBaseURL' in Info.plist")
        }
        manager = SocketManager(socketURL: url, config: [.log(true), .compress])
        socket = manager.defaultSocket
    }
    
    /// 소켓 서버에 연결
    func connect() {
        socket.on(clientEvent: .connect) { _, _ in
            print("Socket connected")
        }
        socket.on(clientEvent: .disconnect) { _, _ in
            print("Socket disconnected")
        }
        socket.connect()
    }
    
    /// 소켓 서버와의 연결을 종료
    func disconnect() {
        socket.disconnect()
    }
    
    /// 주어진 roomId와 userId로 채팅방에 입장
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    func joinRoom(roomId: Int) {
        guard let userId = currentUserId else {
            print("No CurrentUserId found in UserDefaults")
            return
        }
        socket.emit(Event.joinRoom, ["roomId": roomId, "userId": userId])
    }

    /// 주어진 userId에 해당하는 채팅방 목록을 REST API로 요청
    /// - Parameters:
    ///   - completion: 응답으로 받은 채팅방 목록 배열(JSON)을 반환하는 클로저
    func fetchChatRooms(completion: @escaping ([[String: Any]]?) -> Void) {
        guard let userId = currentUserId else {
            print("No CurrentUserId found in UserDefaults")
            completion(nil)
            return
        }
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(urlString)/chatrooms/\(userId)") else {
            print("Invalid APIBaseURL or URL format")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("Failed to fetch chatrooms")
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }

    /// 주어진 roomId에 해당하는 메시지 목록을 REST API로 요청
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - completion: 응답으로 받은 메시지 배열(JSON)을 반환하는 클로저
    func fetchMessages(roomId: Int, completion: @escaping ([[String: Any]]?) -> Void) {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(urlString)/messages/\(roomId)") else {
            print("❌ Invalid APIBaseURL or URL format")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                print("❌ Failed to fetch messages")
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }
    
    /// 메시지를 서버로 전송
    /// - Parameter message: 전송할 메시지 객체
    func sendMessage(_ message: Message) {
        let payload: [String: Any] = [
            "roomId": message.roomId,
            "senderId": message.senderId,
            "content": message.content,
            "createdAt": message.createdAt,
            "isRead": message.isRead
        ]
        socket.emit(Event.sendMessage, payload)
    }
    
    /// 서버로부터 수신한 메시지를 처리하는 핸들러를 등록
    /// - Parameter completion: 수신한 메시지를 반환하는 클로저
    func onReceiveMessage(completion: @escaping (_ message: Message) -> Void) {
        socket.off(Event.receiveMessage)
        socket.on(Event.receiveMessage) { data, _ in
            if let dict = data.first as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: dict),
               let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
                completion(message)
            }
        }
    }
    
    /// 메시지 읽음 이벤트를 수신
    /// - Parameter handler: 읽음 처리할 메시지 ID를 반환하는 클로저
    func onMessageRead(_ handler: @escaping (Int) -> Void) {
        socket.on(Event.messageRead) { data, _ in
            if let messageId = data.first as? Int {
                handler(messageId)
            }
        }
    }
}
