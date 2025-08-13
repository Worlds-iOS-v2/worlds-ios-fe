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
            // 새 메시지 수신 시 unreadCount 업데이트
            .onReceive(NotificationCenter.default.publisher(for: .init("NewMessageReceived"))) { note in
                if let userInfo = note.userInfo,
                   let roomId = userInfo["roomId"] as? Int,
                   let senderId = userInfo["senderId"] as? Int {
                    let currentUserId = UserDefaults.standard.integer(forKey: "userId")
                    
                    // 내가 보낸 메시지가 아닌 경우에만 unreadCount 증가
                    if senderId != currentUserId {
                        if let index = chatRooms.firstIndex(where: { $0.id == roomId }) {
                            chatRooms[index].unreadCount = (chatRooms[index].unreadCount ?? 0) + 1
                        }
                    }
                }
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
    
    // MARK: - 채팅방 로드 함수 분리
    private func loadChatRooms() {
        // Load leftRoomIds from UserDefaults
        if let savedIds = UserDefaults.standard.object(forKey: "leftRoomIds") as? [Int] {
            leftRoomIds = Set(savedIds)
        }
        
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        
        SocketService.shared.fetchChatRooms { rooms in
            guard let rooms = rooms else {
                print("❌ rooms가 nil임")
                return
            }
            DispatchQueue.main.async {
                print("✅ rooms.count: \(rooms.count)")
                
                // 🔥 핵심 수정: 현재 사용자가 참여하고 있고, 나가지 않은 채팅방만 필터링
                self.chatRooms = rooms.filter { room in
                    let isParticipant = (room.userA.id == currentUserId || room.userB.id == currentUserId)
                    let hasNotLeft = !leftRoomIds.contains(room.id)
                    return isParticipant && hasNotLeft
                }
                
                print("✅ 필터링된 채팅방 수: \(self.chatRooms.count)")
            }
        }
    }
}

// ChatRow는 동일하게 유지
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

#Preview {
    ChatListView()
}
