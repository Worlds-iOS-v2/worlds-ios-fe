//
//  ChatDetailView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/3/25.
//

import SwiftUI
import SocketIO
import Translation
import UIKit
import PhotosUI

private extension Notification.Name {
    static let pasteIntoComposer = Notification.Name("PasteIntoComposer")
    static let reportChatMessage = Notification.Name("ReportChatMessage")
}

struct ChatDetailView: View {
    let chat: ChatRoom
    @State private var messageText: String = ""
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var showReportSheet: Bool = false
    @State private var reportTargetMessage: Message? = nil
    @State private var showReportResultAlert: Bool = false
    @State private var reportResultMessage: String = ""
    @State private var showLeaveRoomConfirm: Bool = false
    @State private var isLeavingRoom: Bool = false
    @State private var showLeaveError: Bool = false
    @State private var pickerItem: PhotosPickerItem? = nil

    var targetUserName: String {
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        return (chat.userA.id == currentUserId) ? chat.userB.userName : chat.userA.userName
    }

    // 신고 처리 헬퍼 (View 내부)
    private func reportSelectedMessage(reason: String) {
        guard let msg = reportTargetMessage else { return }
        SocketService.shared.reportMessage(messageId: msg.id, reason: reason) { ok in
            DispatchQueue.main.async {
                self.reportResultMessage = ok ? "신고가 접수되었습니다." : "신고에 실패했어요. 잠시 후 다시 시도해주세요."
                self.showReportResultAlert = true
            }
        }
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
                Menu {
                    // 액션: 필요 시 실제 구현 연결
                    Button {
                        // TODO: 상대 프로필로 이동
                    } label: {
                        Label("상대 프로필", systemImage: "person.crop.circle")
                    }

                    Button {
                        // TODO: OCR 기록 보기
                    } label: {
                        Label("OCR 기록", systemImage: "folder")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showLeaveRoomConfirm = true
                    } label: {
                        Label("채팅방 나가기", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.black)
                }
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
                    // 새로 로드/도착한 받은 메시지들을 읽음 처리
                    viewModel.markUnreadFromOthersAsRead(roomId: chat.id)
                }
            }

            // 입력창
            HStack {
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
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
            .onChange(of: pickerItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        let mimeType = detectMimeType(data: data)
                        let fileName = suggestedFileName(for: newItem, mimeType: mimeType)
                        if let currentUserId = UserDefaults.standard.integer(forKey: "userId") as Int? {
                            SocketService.shared.uploadAttachment(data: data, fileName: fileName, mimeType: mimeType) { fileUrl in
                                guard let fileUrl = fileUrl else { return }

                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                let nowString = formatter.string(from: Date())

                                let message = Message(
                                    id: UUID().hashValue,
                                    roomId: chat.id,
                                    senderId: currentUserId,
                                    content: "", // 이미지 메시지는 텍스트 본문 없음
                                    isRead: false,
                                    createdAt: nowString,
                                    fileUrl: fileUrl,
                                    fileType: mimeType
                                )

                                // 소켓 전송 + 로컬 즉시 반영
                                SocketService.shared.sendMessage(message)
                                DispatchQueue.main.async {
                                    self.viewModel.messages.append(message)
                                }
                            }
                        }
                    }
                    pickerItem = nil
                }
            }
        }
        .background(Color(red: 0.94, green: 0.96, blue: 1.0))
        .onAppear {
            if !chat.messages.isEmpty {
                viewModel.seed(initialMessages: chat.messages)
            }
            viewModel.connectAndJoin(chatId: chat.id)
            viewModel.loadLatestFirst(roomId: chat.id)

            // 초기 로드가 끝난 뒤 읽음 처리
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                viewModel.markUnreadFromOthersAsRead(roomId: chat.id)
            }

            viewModel.listenForMessageRead()
        }
        .onDisappear {
            viewModel.disconnect()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pasteIntoComposer)) { note in
            if let text = note.object as? String, !text.isEmpty {
                self.messageText = text
                self.isTextFieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reportChatMessage)) { note in
            if let msg = note.object as? Message {
                self.reportTargetMessage = msg
                self.showReportSheet = true
            }
        }
        .confirmationDialog("이 메시지를 신고하시겠어요?", isPresented: $showReportSheet) {
            Button("스팸/광고", role: .destructive) { reportSelectedMessage(reason: "spam") }
            Button("욕설/혐오", role: .destructive) { reportSelectedMessage(reason: "abuse") }
            Button("기타", role: .destructive) { reportSelectedMessage(reason: "etc") }
            Button("취소", role: .cancel) {}
        } message: {
            Text(reportTargetMessage?.content ?? "")
        }
        .confirmationDialog("채팅방을 나가시겠어요?", isPresented: $showLeaveRoomConfirm) {
            Button("나가기", role: .destructive) {
                guard !isLeavingRoom else { return }
                isLeavingRoom = true
                SocketService.shared.leaveRoom(roomId: chat.id) { ok in
                    DispatchQueue.main.async {
                        self.isLeavingRoom = false
                        if ok {
                            NotificationCenter.default.post(name: .init("ChatRoomDidLeave"), object: chat.id)
                            dismiss()
                        } else {
                            self.showLeaveError = true
                        }
                    }
                }
            }
            Button("취소", role: .cancel) {}
        }
        .alert("채팅방 나가기에 실패했어요. 잠시 후 다시 시도해주세요.", isPresented: $showLeaveError) {
            Button("확인", role: .cancel) {}
        }
        .alert(reportResultMessage, isPresented: $showReportResultAlert) {
            Button("확인", role: .cancel) {}
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

    @State private var showTranslated: Bool = false
    @State private var isTranslating: Bool = false
    @State private var translatedText: String? = nil
    @State private var translationConfigurationAny: Any? = nil

    @available(iOS 18.0, *)
    private func handleTranslation(session: TranslationSession) async {
        do {
            let response = try await session.translate(message.content)
            await MainActor.run {
                self.translatedText = response.targetText
                self.showTranslated = true
                self.isTranslating = false
                self.translationConfigurationAny = nil
            }
        } catch {
            await MainActor.run {
                print("❌ 번역 실패(iOS18):", error.localizedDescription)
                self.isTranslating = false
                self.translationConfigurationAny = nil
            }
        }
    }

    private func toggleTranslateAction() {
        if showTranslated {
            showTranslated = false
        } else if let _ = translatedText {
            showTranslated = true
        } else {
            isTranslating = true
            if #available(iOS 18.0, *) {
                let targetCode = Locale.current.language.languageCode?.identifier ?? "en"
                translationConfigurationAny = TranslationSession.Configuration(source: nil, target: Locale.Language(identifier: targetCode))
            } else {
                self.isTranslating = false
            }
        }
    }

    private var displayText: String {
        if showTranslated, let t = translatedText, !t.isEmpty {
            return t
        }
        return message.content
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if message.isSender {
                // 보낸 말풍선: 오른쪽 정렬
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    // 1) 버블 + 시간(읽음) 같은 줄
                    HStack(alignment: .bottom, spacing: 6) {
                        // 시간 + 읽음 (버블의 왼쪽)
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

                        // 말풍선 또는 이미지
                        if let urlStr = message.fileUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(width: 180, height: 180)
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                        .frame(maxWidth: 220, maxHeight: 220)
                                        .clipped()
                                        .cornerRadius(15)
                                case .failure:
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 180, height: 180)
                                        .overlay(Image(systemName: "photo"))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Text(displayText)
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(15)
                                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .contextMenu {
                                    Button("복사하기", systemImage: "doc.on.doc") {
                                        UIPasteboard.general.string = message.content
                                    }
                                    Button("붙여넣기", systemImage: "doc.on.clipboard") {
                                        let text = UIPasteboard.general.string ?? ""
                                        NotificationCenter.default.post(name: .pasteIntoComposer, object: text)
                                    }
                                    Divider()
                                    Button("신고하기", systemImage: "exclamationmark.bubble", role: .destructive) {
                                        NotificationCenter.default.post(name: .reportChatMessage, object: message)
                                    }
                                }
                        }
                    }

                    // 2) 번역 토글 버튼 (버블 아래, 오른쪽 정렬)
                    Button(action: {
                        toggleTranslateAction()
                    }) {
                        Text(isTranslating ? "번역 중…" : (showTranslated ? "원문보기" : "번역하기"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .disabled(isTranslating)
                }
            } else {
                // 받은 말풍선: 왼쪽 정렬
                VStack(alignment: .leading, spacing: 4) {
                    // 1) 버블 + 시간 같은 줄
                    HStack(alignment: .bottom, spacing: 6) {
                        // 말풍선 또는 이미지
                        if let urlStr = message.fileUrl, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(width: 180, height: 180)
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                        .frame(maxWidth: 220, maxHeight: 220)
                                        .clipped()
                                        .cornerRadius(15)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                        )
                                case .failure:
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 180, height: 180)
                                        .overlay(Image(systemName: "photo"))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Text(displayText)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .contextMenu {
                                    Button("복사하기", systemImage: "doc.on.doc") {
                                        UIPasteboard.general.string = message.content
                                    }
                                    Button("붙여넣기", systemImage: "doc.on.clipboard") {
                                        let text = UIPasteboard.general.string ?? ""
                                        NotificationCenter.default.post(name: .pasteIntoComposer, object: text)
                                    }
                                    Divider()
                                    Button("신고하기", systemImage: "exclamationmark.bubble", role: .destructive) {
                                        NotificationCenter.default.post(name: .reportChatMessage, object: message)
                                    }
                                }
                        }

                        // 시간 (버블의 오른쪽)
                        Text(timeString(from: message.createdAt))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    // 2) 번역 토글 버튼 (버블 아래, 왼쪽 정렬)
                    Button(action: {
                        toggleTranslateAction()
                    }) {
                        Text(isTranslating ? "번역 중…" : (showTranslated ? "원문보기" : "번역하기"))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .disabled(isTranslating)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .background(
            Group {
                if #available(iOS 18.0, *), let any = translationConfigurationAny, let config = any as? TranslationSession.Configuration {
                    Color.clear
                        .translationTask(config) { session in
                            await handleTranslation(session: session)
                        }
                } else {
                    Color.clear
                }
            }
        )
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

// MARK: - Image Picker Helpers
fileprivate func detectMimeType(data: Data) -> String {
    // JPEG
    if data.starts(with: [0xFF, 0xD8, 0xFF]) {
        return "image/jpeg"
    }
    // PNG
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
        return "image/png"
    }
    // GIF
    if data.starts(with: [0x47, 0x49, 0x46, 0x38]) {
        return "image/gif"
    }
    // HEIC/HEIF
    if data.count >= 12 {
        let sub = data.subdata(in: 4..<12)
        if let str = String(data: sub, encoding: .ascii), str == "ftypheic" || str == "ftypheif" {
            return "image/heic"
        }
    }
    return "application/octet-stream"
}

fileprivate func suggestedFileName(for pickerItem: PhotosPickerItem, mimeType: String) -> String {
    // Try to use itemIdentifier if available
    if let id = pickerItem.itemIdentifier {
        if mimeType == "image/jpeg" {
            return "\(id).jpg"
        } else if mimeType == "image/png" {
            return "\(id).png"
        } else if mimeType == "image/gif" {
            return "\(id).gif"
        } else if mimeType == "image/heic" {
            return "\(id).heic"
        }
    }
    // Default fallback
    switch mimeType {
    case "image/jpeg": return "image.jpg"
    case "image/png": return "image.png"
    case "image/gif": return "image.gif"
    case "image/heic": return "image.heic"
    default: return "file"
    }
}

