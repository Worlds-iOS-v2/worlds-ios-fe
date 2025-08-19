//
//  ChatListView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/3/25.
//

import SwiftUI

struct ChatListView: View {
    @State private var chatRooms: [ChatRoom] = []
    @State private var isPresentingAddChatView = false
    @State private var leftRoomIds: Set<Int> = UserDefaults.standard.object(forKey: "leftRoomIds") as? Set<Int> ?? []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Bar
                HStack(alignment: .firstTextBaseline) {
                    Text("채팅")
                        .font(.system(size: 26, weight: .semibold))
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                        .onTapGesture {
                                isPresentingAddChatView = true
                        }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .foregroundColor(.black)

                // 채팅방 리스트
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(chatRooms) { chat in
                            NavigationLink(destination: ChatDetailView(chat: chat)) {
                                ChatRow(chat: chat)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                // 🔥 Pull-to-Refresh 기능 추가
                .refreshable {
                    await refreshChatRooms()
                }
            }
            .onAppear {
                loadChatRooms()
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("ChatRoomDidLeave"))) { note in
                if let roomId = note.object as? Int {
                    leftRoomIds.insert(roomId)
                    // Save updated leftRoomIds to UserDefaults
                    UserDefaults.standard.set(Array(leftRoomIds), forKey: "leftRoomIds")
                    chatRooms.removeAll { $0.id == roomId }
                }
            }
            // 🔥 개선된 새 메시지 수신 처리
            .onReceive(NotificationCenter.default.publisher(for: .init("NewMessageReceived"))) { note in
                handleNewMessage(note)
            }
            // 메시지 읽음 처리 시 unreadCount 업데이트
            .onReceive(NotificationCenter.default.publisher(for: .init("MessagesRead"))) { note in
                if let userInfo = note.userInfo,
                   let roomId = userInfo["roomId"] as? Int {
                    if let index = chatRooms.firstIndex(where: { $0.id == roomId }) {
                        chatRooms[index].unreadCount = 0
                    }
                }
            }
            .background(Color(red: 0.94, green: 0.96, blue: 1.0))
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $isPresentingAddChatView) {
                AddChatView()
            }
        }
    }
    
    // 🔥 새 메시지 처리 함수 (완전한 실시간 업데이트)
    private func handleNewMessage(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let roomId = userInfo["roomId"] as? Int,
              let senderId = userInfo["senderId"] as? Int else {
            return
        }
        
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        
        // 🔥 1단계: 해당 채팅방 찾아서 업데이트
        if let index = chatRooms.firstIndex(where: { $0.id == roomId }) {
            var updatedRoom = chatRooms[index]
            
            // 🔥 2단계: 새 메시지 정보가 있으면 마지막 메시지로 업데이트
            if let messageContent = userInfo["content"] as? String,
               let createdAt = userInfo["createdAt"] as? String {
                
                // 새 메시지 객체 생성
                let newMessage = Message(
                    id: userInfo["messageId"] as? Int ?? Int.random(in: 1...999999),
                    roomId: roomId,
                    senderId: senderId,
                    content: messageContent,
                    isRead: senderId == currentUserId, // 내가 보낸 메시지는 읽음 처리
                    createdAt: createdAt,
                    fileUrl: userInfo["fileUrl"] as? String,
                    fileType: userInfo["fileType"] as? String
                )
                
                // 기존 메시지 배열에서 중복 제거 후 추가
                var messages = updatedRoom.messages
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                }
                updatedRoom.messages = messages
                
                print("🔄 [ChatList] 마지막 메시지 업데이트: \(messageContent)")
            }
            
            // 🔥 3단계: 내가 보낸 메시지가 아니면 읽지 않은 개수 증가
            if senderId != currentUserId {
                updatedRoom.unreadCount = (updatedRoom.unreadCount ?? 0) + 1
                print("🔄 [ChatList] 읽지 않은 메시지 증가: \(updatedRoom.unreadCount ?? 0)")
            }
            
            // 4단계: 배열 업데이트
            chatRooms[index] = updatedRoom
            
            // 🔥 5단계: 최신 메시지 순으로 정렬 (새 메시지가 온 채팅방이 맨 위로)
            chatRooms.sort { room1, room2 in
                let date1 = room1.messages.last?.createdAt ?? ""
                let date2 = room2.messages.last?.createdAt ?? ""
                return date1 > date2
            }
            
            print("🔄 [ChatList] 채팅방 순서 재정렬 완료")
        }
    }
    
    // 🔥 Pull-to-Refresh 함수 추가
    private func refreshChatRooms() async {
        print("🔄 [ChatList] Pull-to-refresh 시작")
        
        return await withCheckedContinuation { continuation in
            // Load leftRoomIds from UserDefaults
            if let savedIds = UserDefaults.standard.object(forKey: "leftRoomIds") as? [Int] {
                leftRoomIds = Set(savedIds)
            }
            
            let currentUserId = UserDefaults.standard.integer(forKey: "userId")
            
            SocketService.shared.fetchChatRooms { rooms in
                guard let rooms = rooms else {
                    print("❌ [Refresh] rooms가 nil임")
                    continuation.resume()
                    return
                }
                
                DispatchQueue.main.async {
                    print("✅ [Refresh] 새로고침된 rooms.count: \(rooms.count)")
                    
                    // 현재 사용자가 참여하고 있고, 나가지 않은 채팅방만 필터링
                    let filteredRooms = rooms.filter { room in
                        let isParticipant = (room.userA.id == currentUserId || room.userB.id == currentUserId)
                        let hasNotLeft = !leftRoomIds.contains(room.id)
                        return isParticipant && hasNotLeft
                    }
                    
                    // 최신 메시지 순으로 정렬해서 저장
                    self.chatRooms = filteredRooms.sorted { room1, room2 in
                        let date1 = room1.messages.last?.createdAt ?? ""
                        let date2 = room2.messages.last?.createdAt ?? ""
                        return date1 > date2
                    }
                    
                    print("✅ [Refresh] 새로고침 완료! 채팅방 수: \(self.chatRooms.count)")
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - 채팅방 로드 함수 분리 (디버깅 버전)
    private func loadChatRooms() {
        // 🔥 디버깅: UserDefaults 확인
           print("🔍 [DEBUG] UserDefaults 전체 확인:")
           if let userId = UserDefaults.standard.object(forKey: "userId") {
               print("🔍 [DEBUG] userId object: \(userId), type: \(type(of: userId))")
           } else {
               print("🔍 [DEBUG] userId가 UserDefaults에 없음")
           }
           
           // 다른 가능한 키들도 확인
           let possibleKeys = ["userId", "user_id", "currentUserId", "id"]
           for key in possibleKeys {
               if let value = UserDefaults.standard.object(forKey: key) {
                   print("🔍 [DEBUG] \(key): \(value)")
               }
           }
        // Load leftRoomIds from UserDefaults
        if let savedIds = UserDefaults.standard.object(forKey: "leftRoomIds") as? [Int] {
            leftRoomIds = Set(savedIds)
        }
        
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        
        // 🔥 디버깅: 현재 사용자 ID 확인
        print("🔍 [DEBUG] 현재 사용자 ID: \(currentUserId)")
        print("🔍 [DEBUG] leftRoomIds: \(leftRoomIds)")
        
        SocketService.shared.fetchChatRooms { rooms in
            guard let rooms = rooms else {
                print("❌ rooms가 nil임")
                return
            }
            DispatchQueue.main.async {
                print("✅ rooms.count: \(rooms.count)")
                
                // 🔥 디버깅: 각 채팅방 정보 출력
                for (index, room) in rooms.enumerated() {
                    print("🔍 [DEBUG] Room \(index): id=\(room.id), userA=\(room.userA.id), userB=\(room.userB.id)")
                    let isParticipantA = (room.userA.id == currentUserId)
                    let isParticipantB = (room.userB.id == currentUserId)
                    let isParticipant = isParticipantA || isParticipantB
                    let hasNotLeft = !leftRoomIds.contains(room.id)
                    print("🔍 [DEBUG]   isParticipantA: \(isParticipantA)")
                    print("🔍 [DEBUG]   isParticipantB: \(isParticipantB)")
                    print("🔍 [DEBUG]   isParticipant: \(isParticipant)")
                    print("🔍 [DEBUG]   hasNotLeft: \(hasNotLeft)")
                    print("🔍 [DEBUG]   최종 포함 여부: \(isParticipant && hasNotLeft)")
                }
                
                // 현재 사용자가 참여하고 있고, 나가지 않은 채팅방만 필터링
                let filteredRooms = rooms.filter { room in
                    let isParticipant = (room.userA.id == currentUserId || room.userB.id == currentUserId)
                    let hasNotLeft = !leftRoomIds.contains(room.id)
                    return isParticipant && hasNotLeft
                }
                
                // 🔥 최신 메시지 순으로 정렬해서 저장
                self.chatRooms = filteredRooms.sorted { room1, room2 in
                    let date1 = room1.messages.last?.createdAt ?? ""
                    let date2 = room2.messages.last?.createdAt ?? ""
                    return date1 > date2
                }
                
                print("✅ 필터링된 채팅방 수: \(self.chatRooms.count)")
                
                // 🔥 디버깅: 최종 결과 출력
                for (index, room) in self.chatRooms.enumerated() {
                    print("🔍 [DEBUG] 최종 Room \(index): id=\(room.id), name=\(room.name)")
                }
            }
        }
    }
}

struct ChatRow: View {
    var chat: ChatRoom
    
    var currentUserId = UserDefaults.standard.integer(forKey: "userId")
    let partnerName: String

    init(chat: ChatRoom) {
        self.chat = chat
        self.currentUserId = UserDefaults.standard.integer(forKey: "userId")
        self.partnerName = (chat.userA.id == currentUserId) ? chat.userB.userName : chat.userA.userName
    }
    
    // 디버깅을 위한 계산된 속성들
    private var serverUnreadCount: Int? {
        chat.unreadCount
    }
    
    private var localUnreadCount: Int {
        // 안전한 접근을 위한 guard 문 추가
        guard let messages = chat.messages as [Message]? else {
            return 0
        }
        
        let unreadMessages = messages.filter { message in
            return !message.isRead && message.senderId != currentUserId
        }
        
        return unreadMessages.count
    }
    
    // 로컬에서 계산한 값을 우선 사용, 서버 값은 참고용으로만
        private var unreadCount: Int {
            // 로컬에서 계산한 값 사용 (서버 값보다 정확함)
            return localUnreadCount
        }
    
    private var unreadBadgeText: String {
        unreadCount > 99 ? "99+" : "\(unreadCount)"
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(partnerName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                if let lastMessage = chat.messages.last {
                    if let fileUrl = lastMessage.fileUrl, !fileUrl.isEmpty {
                        Text("사진")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                } else {
                    Text("새로운 채팅을 시작해보세요")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if let lastMessage = chat.messages.last {
                    Text(lastMessage.formattedDate)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                // 읽지 않은 메시지 배지
                if unreadCount > 0 {
                    Text(unreadBadgeText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .padding(.horizontal, unreadCount > 9 ? 4 : 0)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.22, green: 0.47, blue: 0.99))
                        )
                        .accessibilityLabel("읽지 않은 메시지 \(unreadCount)개")
                        .animation(.easeInOut(duration: 0.2), value: unreadCount)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            // ChatRow가 나타날 때마다 디버깅 정보 출력
            _ = localUnreadCount // 이렇게 하면 디버깅 로그가 출력됨
        }
    }
}

extension Message {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"

        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = isoFormatter.date(from: createdAt) {
            return formatter.string(from: date)
        }
        return createdAt
    }
}
