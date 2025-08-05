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
                Text(chat.name)
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
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
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

                Button(action: {
                    guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    viewModel.sendMessage(chatId: chat.id, userId: "your-user-id", content: messageText) // 실제 사용자 id로 교체
                    messageText = ""
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
            viewModel.connectAndJoin(chatId: chat.id)
            viewModel.listenForMessageRead()
        }
        .onDisappear {
            viewModel.disconnect()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

// 말풍선
struct ChatBubble: View {
    var message: Message

    var body: some View {
        VStack(alignment: message.isSender ? .trailing : .leading, spacing: 2) {
            HStack {
                if message.isSender {
                    Spacer()
                    Text(message.content)
                        .padding(10)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(15)
                } else {
                    Text(message.content)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                    Spacer()
                }
            }

            if message.isSender {
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        if message.isRead {
                            Text("읽음")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        Text(timeString(from: message.createdAt))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 4)
                    Spacer().frame(width: 50)
                }
                .padding(.trailing, 10)
            } else {
                HStack {
                    Spacer()
                    Text(timeString(from: message.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 10)
            }
        }
        .padding(.horizontal, 10)
    }

    func timeString(from isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoDate) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: date)
        }
        return ""
    }
}
