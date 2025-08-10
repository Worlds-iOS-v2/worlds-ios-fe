//
//  ChatDetailView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/3/25.
//

import SwiftUI
import SocketIO

struct ChatDetailView: View {
    let chat: ChatRoom
    @State private var messageText: String = ""
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var targetUserName: String {
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        return (chat.userA.id == currentUserId) ? chat.userB.userName : chat.userA.userName
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                Spacer()
                Text(targetUserName)
                    .font(.headline)
                    .bold()
                Spacer()
                Image(systemName: "chevron.left") // Invisible spacer to keep center alignment
                    .foregroundColor(.clear)
            }
            .padding()

            // 메시지 목록
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                viewModel.loadOlder(roomId: chat.id)
                            }
                        ForEach(viewModel.groupedMessages.keys.sorted(by: { headerDate(from: $0) < headerDate(from: $1) }), id: \.self) { date in
                            VStack(alignment: .leading, spacing: 4) {
                                DateHeader(dateString: date)
                                ForEach(viewModel.groupedMessages[date] ?? [], id: \.id) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            // 입력창
            HStack {
                Button(action: {
                    // 이미지 전송 로직 (추후 구현)
                }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                }

                TextField("메시지를 입력하세요", text: $messageText)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)

                Button(action: {
                    guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    if let currentUserId = UserDefaults.standard.integer(forKey: "userId") as Int? {
                        viewModel.sendMessage(chatId: chat.id, userId: currentUserId, content: messageText)
                    }
                    messageText = ""
                    isTextFieldFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(red: 0.94, green: 0.96, blue: 1.0))
        }
        .background(Color(red: 0.94, green: 0.96, blue: 1.0))
        .onAppear {
            if !chat.messages.isEmpty {
                viewModel.seed(initialMessages: chat.messages)
            }
            viewModel.connectAndJoin(chatId: chat.id)
            viewModel.loadLatestFirst(roomId: chat.id)
            viewModel.listenForMessageRead()
        }
        .onDisappear {
            viewModel.disconnect()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// 날짜 헤더 뷰
struct DateHeader: View {
    let dateString: String
    var body: some View {
        Text(dateString)
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.bottom, 4)
    }
}

// 말풍선
struct ChatBubble: View {
    var message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if message.isSender {
                Spacer()

                // 시간 + 읽음
                VStack(alignment: .trailing, spacing: 2) {
                    if message.isRead {
                        Text("읽음")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Text(timeString(from: message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                // 말풍선
                Text(message.content)
                    .padding(10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(15)

            } else {
                // 말풍선
                Text(message.content)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )

                // 시간
                Text(timeString(from: message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.gray)

                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }

    func timeString(from dateString: String) -> String {
        // 1. ISO 형식 시도
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let isoDate = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: isoDate)
        }

        // 2. 일반적인 날짜 형식 시도 (예비 처리)
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let fallbackDate = fallbackFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: fallbackDate)
        }

        return "(시간 오류)"
    }
}

// MARK: - Local helper for header sorting (View-only)
fileprivate func headerDate(from header: String) -> Date {
    // Expected header like: "2025년 8월 10일 일요일"
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "ko_KR")
    fmt.calendar = Calendar(identifier: .gregorian)
    fmt.dateFormat = "yyyy년 M월 d일 EEEE"
    if let d = fmt.date(from: header) {
        return d
    }
    // Fallback
    let alt = DateFormatter()
    alt.locale = Locale(identifier: "en_US_POSIX")
    alt.calendar = Calendar(identifier: .gregorian)
    alt.dateFormat = "yyyy-MM-dd"
    return alt.date(from: header) ?? Date.distantPast
}
