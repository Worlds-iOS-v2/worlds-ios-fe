//
//  SocketService.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/4/25.
//

import Foundation
import SocketIO

// Wrapper struct for decoding chat room server response
struct ChatRoomResponseWrapper: Codable {
    let data: [ChatRoom]
}

class SocketService {
    static let shared = SocketService()
    
    private var currentUserId: Int? {
        return UserDefaults.standard.value(forKey: "userId") as? Int
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
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: baseUrl) else {
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
    func fetchChatRooms(completion: @escaping ([ChatRoom]?) -> Void) {
        guard let userId = currentUserId else {
            print("No CurrentUserId found in UserDefaults")
            completion(nil)
            return
        }
        print("🔍 fetchChatRooms with userId:", userId)
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chat/chatrooms/\(userId)") else {
            print("Invalid APIBaseURL or URL format")
            completion(nil)
            return
        }
        print("🌐 Requesting URL:", url.absoluteString)

        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("accessToken 없음")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Failed to fetch chatrooms")
                completion(nil)
                return
            }
            print("Received data:", data)
            print("Response string:", String(data: data, encoding: .utf8) ?? "디코딩 실패")
            do {
                let decoded = try JSONDecoder().decode([ChatRoom].self, from: data)
                print("Decoded chatRooms:", decoded.count)
                completion(decoded)
            } catch {
                print("Decoding error:", error)
                completion(nil)
            }
        }
        task.resume()
    }

    /// 주어진 roomId에 해당하는 메시지 목록을 REST API로 요청 (take/skip 지원)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - take: 가져올 개수
    ///   - skip: 건너뛸 개수
    ///   - completion: 응답으로 받은 메시지 배열(JSON)을 반환하는 클로저
    func fetchMessages(roomId: Int, take: Int, skip: Int, completion: @escaping ([[String: Any]]?) -> Void) {
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chat/messages/\(roomId)?take=\(take)&skip=\(skip)") else {
            print("❌ Invalid APIBaseURL or URL format")
            completion(nil)
            return
        }

        print("📡 Fetching messages from URL:", url)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ accessToken 없음. 메시지 불러오기 중단")
            completion(nil)
            return
        }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error while fetching messages:", error)
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Status code:", httpResponse.statusCode)
                if !(200...299).contains(httpResponse.statusCode) {
                    print("❌ 서버 비정상 응답. body:", String(data: data ?? Data(), encoding: .utf8) ?? "nil")
                    completion(nil)
                    return
                }
            }

            guard let data = data else {
                print("❌ No data received")
                completion(nil)
                return
            }

            print("📦 Raw message data:", String(data: data, encoding: .utf8) ?? "디코딩 실패")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("✅ Parsed message count:", json.count)
                    completion(json)
                } else {
                    print("❌ JSON 구조가 [[String: Any]]가 아님")
                    completion(nil)
                }
            } catch {
                print("❌ JSON 파싱 에러:", error)
                completion(nil)
            }
        }

        task.resume()
    }

    /// (레거시) 기본값으로 호출할 수 있는 편의 메서드. 추후 제거 예정.
    func fetchMessages(roomId: Int, completion: @escaping ([[String: Any]]?) -> Void) {
        let defaultTake = 20
        let defaultSkip = 0
        fetchMessages(roomId: roomId, take: defaultTake, skip: defaultSkip, completion: completion)
    }
    
    /// 메시지를 서버로 전송
    /// - Parameter message: 전송할 메시지 객체
    func sendMessage(_ message: Message) {
        guard let senderId = currentUserId else {
            print("currentUserId 없음. 메시지 전송 불가")
            return
        }

        let payload: [String: Any] = [
            "roomId": message.roomId,
            "senderId": senderId,
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
            print("Raw receive_message data:", data)
            if let dict = data.first as? [String: Any] {
                print("Parsed dictionary:", dict)
                if let jsonData = try? JSONSerialization.data(withJSONObject: dict) {
                    print("JSON data string:", String(data: jsonData, encoding: .utf8) ?? "nil")
                    if let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
                        print("Decoded Message:", message)
                        completion(message)
                    } else {
                        print("Failed to decode Message from jsonData")
                    }
                } else {
                    print("Failed to serialize dictionary to JSON")
                }
            } else {
                print("Failed to cast data[0] to dictionary")
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
    
    func createChatRoom(with targetUserId: String, completion: @escaping (ChatRoom?) -> Void) {
        guard let myUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("내 userId 없음")
            completion(nil)
            return
        }

        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chatroom/create") else {
            print("APIBaseURL 로딩 실패 또는 URL 생성 실패")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "myUserId": myUserId,
            "targetUserId": targetUserId
        ]
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 채팅방 생성 실패:", error)
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                print("서버 응답 이상 또는 데이터 없음")
                completion(nil)
                return
            }

            do {
                let chatRoom = try JSONDecoder().decode(ChatRoom.self, from: data)
                print("채팅방 생성 성공:", chatRoom)
                completion(chatRoom)
            } catch {
                print("채팅방 디코딩 실패:", error)
                completion(nil)
            }
        }.resume()
    }
}
