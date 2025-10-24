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
        static let readMessage = "read_message"      // ← 내가 emit 할 때
        static let messageRead = "messages_read"     // ← 서버가 브로드캐스트
    }
    
    private var manager: SocketManager!
    var socket: SocketIOClient!
    
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
        if socket.status == .connected {
            print("⚠️ 이미 연결되어 있음")
            return
        }
        
        socket.on(clientEvent: .connect) { _, _ in
            print("✅ [SOCKET] 연결 성공!")
        }
        
        socket.on(clientEvent: .disconnect) { _, _ in
            print("❌ [SOCKET] 연결 끊어짐")
        }
        
        socket.on(clientEvent: .error) { data, _ in
            print("🚨 [SOCKET] 에러: \(data)")
        }
        
        print("🔌 [SOCKET] 연결 시도 중...")
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
            print("❌ currentUserId 없음")
            return
        }
        
        let payload = ["roomId": roomId, "userId": userId]
        
        // 🔥 연결되어 있으면 바로 emit
        if socket.status == .connected {
            print("🏠 [SOCKET] 방 참여 시도: \(payload)")
            socket.emit(Event.joinRoom, payload)
        } else {
            print("⏳ [SOCKET] 연결 대기 후 방 참여 예약")
            socket.once(clientEvent: .connect) { [weak self] _, _ in
                print("🏠 [SOCKET] 연결 완료 - 방 참여 시도: \(payload)")
                self?.socket.emit(Event.joinRoom, payload)
            }
        }
        
        // 방 참여 응답 리스너
        socket.on("join_room_response") { data, _ in
            print("✅ [SOCKET] 방 참여 응답: \(data)")
        }
    }

    /// 채팅방 목록을 REST API로 요청 (JWT 기반) - 디버깅 버전
    /// - Backend now supports unreadCount per chat room.
    /// - Parameters:
    ///   - completion: 응답으로 받은 채팅방 목록 배열(JSON)을 반환하는 클로저
    func fetchChatRooms(completion: @escaping ([ChatRoom]?) -> Void) {
        print("🔍 fetchChatRooms (JWT)")
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chat/chatrooms") else {
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
                // 1) 시도: 래퍼 { data: [ChatRoom] }
                if let wrapped = try? JSONDecoder().decode(ChatRoomResponseWrapper.self, from: data) {
                    completion(wrapped.data)
                    return
                }
                
                // 2) 시도: 바로 [ChatRoom]
                let decoded = try JSONDecoder().decode([ChatRoom].self, from: data)
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
            
            if let dict = data.first as? [String: Any] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict)
                    let message = try JSONDecoder().decode(Message.self, from: jsonData)
                    
                    completion(message)
                    
                    // 채팅 목록 업데이트를 위한 상세 알림 전송
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .init("NewMessageReceived"),
                            object: nil,
                            userInfo: [
                                "roomId": message.roomId,
                                "senderId": message.senderId,
                                "messageId": message.id,
                                "content": message.content,
                                "createdAt": message.createdAt,
                                "fileUrl": message.fileUrl ?? "",
                                "fileType": message.fileType ?? ""
                            ]
                        )
                    }
                } catch {
                    print("❌ [SOCKET] 메시지 디코딩 실패: \(error)")
                }
            }
        }
    }
    
    /// 메시지 읽음 이벤트 수신 (서버 브로드캐스트)
    /// handler에는 '상대가 읽었다'고 판단할 수 있는 마지막 messageId를 넘겨줌
    func onMessageRead(_ handler: @escaping (Int) -> Void) {
        // 기존 핸들러 제거
        socket.off(Event.messageRead)
        socket.off("message_read") // 레거시 안전 장치

        // 신규: messages_read
        socket.on(Event.messageRead) { data, _ in
            if let dict = data.first as? [String: Any] {
                if let last = dict["lastReadMessageId"] as? Int {
                    handler(last); return
                }
                if let ids = dict["messageIds"] as? [Int], let maxId = ids.max() {
                    handler(maxId); return
                }
            }
            print("⚠️ onMessageRead(messages_read): 알 수 없는 페이로드", data)
        }

        // 레거시: message_read (혹시 남아있다면)
        socket.on("message_read") { data, _ in
            if let lastId = data.first as? Int {
                handler(lastId); return
            }
            if let dict = data.first as? [String: Any] {
                if let last = dict["lastReadMessageId"] as? Int {
                    handler(last); return
                }
                if let ids = dict["messageIds"] as? [Int], let maxId = ids.max() {
                    handler(maxId); return
                }
            }
            print("⚠️ onMessageRead(legacy message_read): 알 수 없는 페이로드", data)
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

    /// 채팅방 나가기(숨김)
    /// 백엔드: POST /chat/rooms/:roomId/leave (JWT 필요)
    func leaveRoom(roomId: Int, completion: @escaping (Bool) -> Void) {
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chat/rooms/\(roomId)/leave") else {
            print("❌ APIBaseURL 로딩 실패 또는 URL 생성 실패")
            completion(false)
            return
        }
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ accessToken 없음")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = Data() // 빈 바디 허용

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 채팅방 나가기 요청 실패:", error)
                completion(false)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                print("❌ leaveRoom 응답 형식 오류")
                completion(false)
                return
            }
            let ok = (200...299).contains(http.statusCode)
            if !ok {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
                print("❌ leaveRoom 실패 status=\(http.statusCode) body=", body)
            }
            completion(ok)
        }.resume()
    }

    /// 메시지 신고
    /// 백엔드: POST /chat/messages/:messageId/report (JWT 필요)
    /// - Parameters:
    ///   - messageId: 신고할 메시지 ID
    ///   - reason: 선택 사유(백엔드에서 자유 텍스트를 허용하는 경우)
    func reportMessage(messageId: Int, reason: String? = nil, completion: @escaping (Bool) -> Void) {
        guard let baseUrl = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseUrl)/chat/messages/\(messageId)/report") else {
            print("❌ APIBaseURL 로딩 실패 또는 URL 생성 실패")
            completion(false)
            return
        }
        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ accessToken 없음")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let reason = reason, !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let body: [String: Any] = ["reason": reason]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        } else {
            request.httpBody = Data() // 빈 바디 허용
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 메시지 신고 요청 실패:", error)
                completion(false)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                print("❌ reportMessage 응답 형식 오류")
                completion(false)
                return
            }
            let ok = (200...299).contains(http.statusCode)
            if !ok {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? "<no body>"
                print("❌ reportMessage 실패 status=\(http.statusCode) body=", body)
            }
            completion(ok)
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
            "messageIds": [messageId]
        ]
        print("📤 emit read_message:", payload)
        socket.emit(Event.readMessage, payload)
    }

    /// 여러 메시지 일괄 읽음 처리(소켓 emit)
    /// 서버가 단건만 받는다면 내부에서 최대값(lastReadMessageId)만 전달
    /// - Parameters:
    ///   - roomId: 채팅방 ID
    ///   - messageIds: 읽음 처리할 메시지 ID 배열
    func emitMessagesRead(roomId: Int, messageIds: [Int]) {
        guard let userId = currentUserId, !messageIds.isEmpty else { return }
        let payload: [String: Any] = [
            "roomId": roomId,
            "userId": userId,
            "messageIds": messageIds
        ]
        print("📤 emit read_message (bulk):", payload)
        socket.emit(Event.readMessage, payload)
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
        let rawToken = token
        let cleanedToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔎 claim raw token:", rawToken)
        print("🔎 claim cleaned token:", cleanedToken)
        let body = ["token": cleanedToken]
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
                print("🎯 [Socket] claimPairing 성공: roomId=\(room.id)")
                
                // 새로 연결된 방은 leftRoomIds에서 제거하고 숨김 해제
                DispatchQueue.main.async {
                    var leftRooms = Set(UserDefaults.standard.array(forKey: "leftRoomIds") as? [Int] ?? [])
                    leftRooms.remove(room.id)
                    UserDefaults.standard.set(Array(leftRooms), forKey: "leftRoomIds")
                    print("🎯 [Socket] leftRoomIds에서 제거: \(room.id)")
                    
                    // 백엔드에서 방 숨김 해제 (APIService 사용)
                    Task {
                        do {
                            let unhideResponse = try await APIService.shared.unhideRoom(roomId: room.id)
                            print("✅ [Socket] 방 숨김 해제 성공: roomId=\(unhideResponse.roomId), unhiddenFor=\(unhideResponse.unhiddenFor), alreadyVisible=\(unhideResponse.alreadyVisible)")
                            
                            // 채팅방 목록 새로고침 알림
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .init("RefreshChatRooms"), object: nil)
                            }
                            
                        } catch {
                            print("[Socket] 방 숨김 해제 실패: \(error)")
                            // 실패해도 계속 진행
                        }
                    }
                }
                
                completion(room)
            } catch {
                print("❌ [Socket] claimPairing 디코딩 실패: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    /// 현재 보이는 메시지 중 내가 보낸 게 아닌 마지막 메시지까지 읽음 emit
    func emitReadUpToLastIncoming(roomId: Int, messages: [Message]) {
        guard let me = currentUserId else { return }
        // 상대가 보낸 메시지들 중 가장 큰 id
        let lastIncomingId = messages.filter { $0.roomId == roomId && $0.senderId != me }
            .map { $0.id }
            .max()
        if let lastId = lastIncomingId {
            emitMessagesRead(roomId: roomId, messageIds: [lastId])
        }
    }
}
