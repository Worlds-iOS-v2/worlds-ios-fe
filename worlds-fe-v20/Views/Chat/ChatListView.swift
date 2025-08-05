//
//  ChatListView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/3/25.
//

import SwiftUI

struct ChatListView: View {
    let mockChats: [ChatRoom] = [
        ChatRoom(
            id: 1,
            userAId: 1,
            userBId: 2,
            createdAt: "2025-08-01T12:00:00Z",
            userA: ChatUser(id: 1, userName: "나"),
            userB: ChatUser(id: 2, userName: "김도영 선생님"),
            messages: [
                Message(
                    id: 1,
                    roomId: 1,
                    senderId: 2,
                    content: "안녕하세요!",
                    isRead: true,
                    createdAt: "2025-08-01T12:05:00Z"
                )
            ]
        )
    ]

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
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .foregroundColor(.black)

                // 채팅방 리스트
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(mockChats) { chat in
                            NavigationLink(destination: ChatDetailView(chat: chat)) {
                                ChatRow(chat: chat)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color(red: 0.94, green: 0.96, blue: 1.0))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ChatRow: View {
    var chat: ChatRoom

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(chat.userB.userName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(chat.messages.last?.content ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(chat.messages.last?.formattedDate ?? "")
                .font(.footnote)
                .foregroundColor(.gray)
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

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: createdAt) {
            return formatter.string(from: date)
        }
        return createdAt
    }
}

#Preview {
    ChatListView()
}
