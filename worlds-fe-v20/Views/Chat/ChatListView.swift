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
                // Load leftRoomIds from UserDefaults
                if let savedIds = UserDefaults.standard.object(forKey: "leftRoomIds") as? [Int] {
                    leftRoomIds = Set(savedIds)
                }
                SocketService.shared.fetchChatRooms { rooms in
                    guard let rooms = rooms else {
                        print("❌ rooms가 nil임")
                        return
                    }
                    DispatchQueue.main.async {
                        print("✅ rooms.count: \(rooms.count)")
                        self.chatRooms = rooms.filter { !leftRoomIds.contains($0.id) }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("ChatRoomDidLeave"))) { note in
                if let roomId = note.object as? Int {
                    leftRoomIds.insert(roomId)
                    // Save updated leftRoomIds to UserDefaults
                    UserDefaults.standard.set(Array(leftRoomIds), forKey: "leftRoomIds")
                    chatRooms.removeAll { $0.id == roomId }
                }
            }
            .background(Color(red: 0.94, green: 0.96, blue: 1.0))
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $isPresentingAddChatView) {
                AddChatView()
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

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(partnerName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(chat.messages.last?.content ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            if let lastMessage = chat.messages.last {
                Text(lastMessage.formattedDate)
                    .font(.footnote)
                    .foregroundColor(.gray)
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
