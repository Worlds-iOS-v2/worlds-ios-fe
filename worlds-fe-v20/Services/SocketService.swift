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
        static let markRead = "message_read" // emit용 (서버와 동일 이벤트명 사용)
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

        var payload: [String: Any] = [
            "roomId": message.roomId,
            "senderId": senderId,
            "content": message.content,
            "createdAt": message.createdAt,
            "isRead": message.isRead
        ]

        if let fileUrl = message.fileUrl {
            payload["fileUrl"] = fileUrl
        }
        if let fileType = message.fileType {
            payload["fileType"] = fileType
        }

        socket.emit(Event.sendMessage, payload)
    }

    // 파일 업로드 API
    func uploadAttachment(data: Data, fileName: String, mimeType: String, completion: @escaping (String?) -> Void) {
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chat/attachments/upload") else {
            completion(nil)
            return
        }
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fileUrl = json["fileUrl"] as? String else {
                completion(nil)
                return
            }
            completion(fileUrl)
        }.resume()
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
    /// 단일 메시지 읽음 처리(소켓 emit)
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - messageId: 읽음 처리할 메시지 ID
    func emitMessageRead(roomId: Int, messageId: Int) {
        guard let userId = currentUserId else {
            print("❌ emitMessageRead 실패: currentUserId 없음")
            return
        }
        let payload: [String: Any] = [
            "roomId": roomId,
            "userId": userId,
            "messageId": messageId
        ]
        print("📤 emit message_read:", payload)
        socket.emit(Event.markRead, payload)
    }

    /// 여러 메시지 일괄 읽음 처리(소켓 emit)
    /// 서버가 단건만 받는다면 내부에서 순차 호출
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - messageIds: 읽음 처리할 메시지 ID 배열
    func emitMessagesRead(roomId: Int, messageIds: [Int]) {
        guard !messageIds.isEmpty else { return }
        // 서버가 배열 payload를 받도록 구현되어 있다면 아래 주석을 사용하고,
        // 단건만 받는다면 forEach로 단건 emit
        // let payload: [String: Any] = [
        //     "roomId": roomId,
        //     "userId": currentUserId ?? 0,
        //     "messageIds": messageIds
        // ]
        // socket.emit(Event.markRead, payload)

        messageIds.forEach { emitMessageRead(roomId: roomId, messageId: $0) }
    }
}

// MARK: - QR API
extension SocketService {
    private struct PairingCreateResponse: Codable {
        let token: String
        let expiresAt: String
    }

    /// 1) QR 생성: POST /pairings → { token, expiresAt }
    func createPairingToken(completion: @escaping (_ token: String?, _ expiresAt: String?) -> Void) {
        guard let base = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: base + "/pairings") else {
            print("❌ APIBaseURL 로딩 실패 또는 URL 생성 실패")
            completion(nil, nil)
            return
        }
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ accessToken 없음")
            completion(nil, nil)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [:])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                print("❌ 요청 실패 @ \(url.absoluteString):", err)
                completion(nil, nil)
                return
            }
            guard let http = resp as? HTTPURLResponse else {
                print("❌ 응답 형식 오류 @ \(url.absoluteString)")
                completion(nil, nil)
                return
            }
            print("📥 \(url.absoluteString) status=\(http.statusCode)")
            guard (200...299).contains(http.statusCode), let data = data else {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
                print("❌ 요청 실패 body=\(body) @ \(url.absoluteString)")
                completion(nil, nil)
                return
            }
            do {
                let decoded = try JSONDecoder().decode(PairingCreateResponse.self, from: data)
                completion(decoded.token, decoded.expiresAt)
            } catch {
                print("❌ 디코딩 실패 @ \(url.absoluteString):", error)
                completion(nil, nil)
            }
        }.resume()
    }

    /// 2) QR 스캔(상대): POST /pairings/claim { token } → ChatRoom
    func claimPairing(token: String, completion: @escaping (ChatRoom?) -> Void) {
        guard let base = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: base + "/pairings/claim") else {
            print("❌ APIBaseURL 로딩 실패 또는 URL 생성 실패")
            completion(nil)
            return
        }
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ accessToken 없음")
            completion(nil)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let body = ["token": token]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                print("❌ 요청 실패 @ \(url.absoluteString):", err)
                completion(nil)
                return
            }
            guard let http = resp as? HTTPURLResponse else {
                print("❌ 응답 형식 오류 @ \(url.absoluteString)")
                completion(nil)
                return
            }
            print("📥 \(url.absoluteString) status=\(http.statusCode)")
            guard (200...299).contains(http.statusCode), let data = data else {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
                print("❌ 요청 실패 body=\(body) @ \(url.absoluteString)")
                completion(nil)
                return
            }
            do {
                let room = try JSONDecoder().decode(ChatRoom.self, from: data)
                completion(room)
            } catch {
                print("❌ 디코딩 실패 @ \(url.absoluteString):", error)
                completion(nil)
            }
        }.resume()
    }
}
