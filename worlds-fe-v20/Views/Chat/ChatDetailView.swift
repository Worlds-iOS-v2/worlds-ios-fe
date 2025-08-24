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
    
    // 사진 확대 보기 관련 상태
    @State private var showImageViewer: Bool = false
    @State private var selectedImageURL: String = ""

    var targetUserName: String {
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        return (chat.userA.id == currentUserId) ? chat.userB.userName : chat.userA.userName
    }

    // 신고 처리
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
        ZStack {
            VStack {
                Spacer()
                
                Image("chatdetailbackgroundws")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .opacity(0.8)
                    .padding(.bottom, 50)
            }
            .ignoresSafeArea(.all, edges: .bottom)
            
            VStack(spacing: 0) {
                // 헤더 (뒤로가기, 사용자명, 메뉴)
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.mainws)
                            .font(.system(size: 24, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    Text(targetUserName)
                        .font(.pretendard(.regular, size: 20))
                        .bold()
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            // TODO: 상대 프로필로 이동
                        } label: {
                            Label("상대 프로필", systemImage: "person.crop.circle")
                        }
                        
                        NavigationLink(destination: OCRListView(ocrList: viewModel.ocrList)) {
                            Label("OCR 기록", systemImage: "folder")
                        }
                        .padding(.horizontal, 32)
                        .onAppear{
                            Task {
                                let currentUserId = UserDefaults.standard.integer(forKey: "userId")
                                let partnerUserId = (chat.userA.id == currentUserId) ? chat.userB.id : chat.userA.id
                                
                                print("partnerUserId \(partnerUserId)")
                                await viewModel.fetchOCRList(userID: partnerUserId)
                            }
                        }
                        
                        Divider()

                        Button(role: .destructive) {
                            showLeaveRoomConfirm = true
                        } label: {
                            Label("채팅방 나가기", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                }
                .padding()

                // 메시지 목록
                messageListView

                // 입력창 (사진 선택, 텍스트 입력, 전송)
                inputView
            }
            // 사진 확대 보기 오버레이
            if showImageViewer {
                ImageViewerOverlay(
                    imageURL: selectedImageURL,
                    isPresented: $showImageViewer
                )
            }
        }
        .background(Color.sub2Ws)
        .onAppear {
            // 나간 방인지 체크
            let leftRooms = Set(UserDefaults.standard.array(forKey: "leftRoomIds") as? [Int] ?? [])
            if leftRooms.contains(chat.id) {
                // 나간 방이면 메시지 클리어
                viewModel.clearMessages()
                return
            }
            
            if !chat.messages.isEmpty {
                viewModel.seed(initialMessages: chat.messages)
            }
            setupChatConnection()
        }
        .onDisappear {
            viewModel.disconnect()
            
            // 나간 방이라면 소켓에서도 완전히 나가기
            let leftRooms = Set(UserDefaults.standard.array(forKey: "leftRoomIds") as? [Int] ?? [])
            if leftRooms.contains(chat.id) {
                SocketService.shared.socket.emit("leave_room", ["roomId": chat.id])
            }
        }
        // 노티피케이션 리스너들
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
        // 다이얼로그 및 알럿들
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
    
    // 메시지 목록 뷰
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            viewModel.loadOlder(roomId: chat.id)
                        }
                    
                    messageContentView
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { count in
                handleMessageCountChange(count: count, proxy: proxy)
            }
        }
    }
    
    // 입력창 뷰 (사진 선택, 텍스트 입력, 전송 버튼)
    private var inputView: some View {
        HStack {
            // 사진 선택 버튼
            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
            }

            // 텍스트 입력 필드
            TextField("메시지를 입력하세요", text: $messageText)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .focused($isTextFieldFocused)

            // 전송 버튼
            Button(action: sendMessageAction) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(red: 0.94, green: 0.96, blue: 1.0))
        .onChange(of: pickerItem) { newItem in
            handleImagePicker(newItem)
        }
    }
    
    // 메시지 콘텐츠 (날짜별 그룹화)
    private var messageContentView: some View {
        let sortedDates = getSortedDates()
        
        return ForEach(sortedDates, id: \.self) { date in
            VStack(alignment: .leading, spacing: 4) {
                DateHeader(dateString: date)
                ForEach(viewModel.groupedMessages[date] ?? [], id: \.id) { message in
                    ChatBubble(
                        message: message,
                        onImageTap: { imageURL in
                            selectedImageURL = imageURL
                            showImageViewer = true
                        }
                    )
                    .id(message.id)
                }
            }
        }
    }
    
    /// 날짜별로 정렬된 키 배열 반환
    private func getSortedDates() -> [String] {
        return Array(viewModel.groupedMessages.keys).sorted { date1, date2 in
            headerDate(from: date1) < headerDate(from: date2)
        }
    }
    
    /// 메시지 개수 변경 시 스크롤 및 읽음 처리
    private func handleMessageCountChange(count: Int, proxy: ScrollViewProxy) {
        // 최신 메시지로 자동 스크롤
        if let lastMessage = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
        // 읽음 처리
        viewModel.markUnreadFromOthersAsRead(roomId: chat.id)
    }
    
    /// 텍스트 메시지 전송
    private func sendMessageAction() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        viewModel.sendMessage(chatId: chat.id, userId: currentUserId, content: messageText)
        messageText = ""
        isTextFieldFocused = false
    }
    
    /// 이미지 선택 및 업로드 처리
    private func handleImagePicker(_ newItem: PhotosPickerItem?) {
        guard let newItem = newItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self) {
                let mimeType = detectMimeType(data: data)
                let fileName = suggestedFileName(for: newItem, mimeType: mimeType)
                let currentUserId = UserDefaults.standard.integer(forKey: "userId")
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let nowString = formatter.string(from: Date())
                
                // 임시 메시지 ID (음수로 서버 ID와 구분)
                let tempId = -Int(Date().timeIntervalSince1970 * 1000)
                
                // Base64로 인코딩해서 즉시 표시 (업로드 완료 전까지)
                let base64String = "data:\(mimeType);base64,\(data.base64EncodedString())"
                
                let tempMessage = Message(
                    id: tempId,
                    roomId: chat.id,
                    senderId: currentUserId,
                    content: "",
                    isRead: false,
                    createdAt: nowString,
                    fileUrl: base64String,
                    fileType: mimeType
                )
                
                // 즉시 UI에 표시
                DispatchQueue.main.async {
                    self.viewModel.messages.append(tempMessage)
                    self.viewModel.objectWillChange.send()
                }
                
                // 백그라운드에서 서버 업로드
                SocketService.shared.uploadAttachment(data: data, fileName: fileName, mimeType: mimeType) { fileUrl in
                    guard let fileUrl = fileUrl else {
                        // 업로드 실패 시 임시 메시지 제거
                        DispatchQueue.main.async {
                            if let index = self.viewModel.messages.firstIndex(where: { $0.id == tempId }) {
                                self.viewModel.messages.remove(at: index)
                            }
                        }
                        return
                    }
                    
                    // 업로드 완료 후 실제 URL로 교체
                    DispatchQueue.main.async {
                        if let index = self.viewModel.messages.firstIndex(where: { $0.id == tempId }) {
                            let updatedMessage = Message(
                                id: tempId,
                                roomId: chat.id,
                                senderId: currentUserId,
                                content: "",
                                isRead: false,
                                createdAt: nowString,
                                fileUrl: fileUrl,
                                fileType: mimeType
                            )
                            self.viewModel.messages[index] = updatedMessage
                            SocketService.shared.sendMessage(updatedMessage)
                        }
                    }
                }
            }
            pickerItem = nil
        }
    }
    
    /// 채팅 연결 및 초기 설정
    private func setupChatConnection() {
        print("[ChatDetail] 소켓 연결 시작")

        viewModel.onReceiveMessage()
        viewModel.connectAndJoin(chatId: chat.id)
        viewModel.loadLatestFirst(roomId: chat.id)
        viewModel.listenForMessageRead()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.markUnreadFromOthersAsRead(roomId: chat.id)
        }
    }
}

// 사진 확대 보기 오버레이
struct ImageViewerOverlay: View {
    let imageURL: String
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastMagnification: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // 검은색 배경
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            VStack {
                // 상단 닫기 버튼
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // 확대/축소 가능한 이미지
                imageView
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            // 핀치 확대/축소
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastMagnification
                                    scale *= delta
                                    scale = min(max(scale, 0.5), 3.0)
                                    lastMagnification = value
                                }
                                .onEnded { _ in
                                    lastMagnification = 1.0
                                    if scale < 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                },
                            
                            // 드래그 이동
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        // 더블 탭으로 확대/축소
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                scale = 1.0
            }
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        if imageURL.hasPrefix("data:") {
            // Base64 이미지
            if let image = base64ToUIImage(imageURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("이미지를 불러올 수 없습니다")
                    .foregroundColor(.white)
            }
        } else if let url = URL(string: imageURL) {
            // 일반 URL 이미지
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure:
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("이미지를 불러올 수 없습니다")
                            .foregroundColor(.white)
                    }
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Text("잘못된 이미지 URL입니다")
                .foregroundColor(.white)
        }
    }
    
    private func base64ToUIImage(_ base64String: String) -> UIImage? {
        guard let commaIndex = base64String.firstIndex(of: ",") else { return nil }
        let base64Data = String(base64String[base64String.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64Data) else { return nil }
        return UIImage(data: data)
    }
}

// 날짜 헤더
struct DateHeader: View {
    let dateString: String
    var body: some View {
        Text(dateString)
            .font(.pretendard(.regular, size: 14))
            .foregroundColor(.gray)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.bottom, 4)
    }
}

// 채팅 말풍선
struct ChatBubble: View {
    var message: Message
    var onImageTap: ((String) -> Void)? = nil

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
                self.isTranslating = false
                self.translationConfigurationAny = nil
            }
        }
    }

    /// 번역 버튼 토글 로직
    private func toggleTranslateAction() {
        if showTranslated {
            showTranslated = false
        } else if translatedText != nil {
            showTranslated = true
        } else {
            isTranslating = true
            if #available(iOS 18.0, *) {
                let targetLang = SupportedLanguage.getCurrentLanguageCode()
                translationConfigurationAny = TranslationSession.Configuration(source: nil, target: Locale.Language(identifier: targetLang))
            } else {
                self.isTranslating = false
            }
        }
    }

    /// 표시할 텍스트 (원문 또는 번역문)
    private var displayText: String {
        if showTranslated, let t = translatedText, !t.isEmpty {
            return t
        }
        return message.content
    }
    
    /// 이미지 뷰 (Base64 또는 URL)
    @ViewBuilder
    private func imageView(from urlString: String) -> some View {
        if urlString.hasPrefix("data:") {
            // Base64 이미지 처리 (업로드 중)
            if let image = base64ToUIImage(urlString) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .clipped()
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    )
                    .onTapGesture {
                        onImageTap?(urlString)
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                            Text("이미지 로딩 중...")
                                .font(.pretendard(.regular, size: 14))
                                .foregroundColor(.gray)
                        }
                    )
            }
        } else if let url = URL(string: urlString) {
            // 일반 URL 이미지 (서버 업로드 완료)
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 180, height: 180)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 220, maxHeight: 220)
                        .clipped()
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                        .onTapGesture {
                            onImageTap?(urlString)
                        }
                case .failure:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                Text("이미지 로드 실패")
                                    .font(.pretendard(.regular, size: 14))
                                    .foregroundColor(.red)
                            }
                        )
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 180, height: 180)
                .overlay(Image(systemName: "photo"))
        }
    }
    
    private func base64ToUIImage(_ base64String: String) -> UIImage? {
        guard let commaIndex = base64String.firstIndex(of: ",") else { return nil }
        let base64Data = String(base64String[base64String.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64Data) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if message.isSender {
                // 보낸 메시지 (오른쪽 정렬)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 6) {
                        // 시간 + 읽음 표시
                        VStack(alignment: .trailing, spacing: 2) {
                            if message.isRead {
                                Text("읽음")
                                    .font(.pretendard(.semiBold, size: 12))
                                    .foregroundColor(.mainfontws)
                            }
                            Text(timeString(from: message.createdAt))
                                .font(.pretendard(.medium, size: 12))
                                .foregroundColor(.gray)
                        }

                        // 메시지 버블 (이미지 또는 텍스트)
                        if let urlStr = message.fileUrl, !urlStr.isEmpty {
                            imageView(from: urlStr)
                        } else {
                            Text(displayText)
                                .font(.pretendard(.medium, size: 16))
                                .padding(10)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

                    // 번역 버튼
                    if !message.content.isEmpty {
                        Button(action: toggleTranslateAction) {
                            Text(isTranslating ? "번역 중…" : (showTranslated ? "원문보기" : "번역하기"))
                                .font(.pretendard(.medium, size: 13))
                                .foregroundColor(.gray)
                        }
                        .disabled(isTranslating)
                    }
                }
            } else {
                // 받은 메시지 (왼쪽 정렬)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 6) {
                        // 메시지 버블 (이미지 또는 텍스트)
                        if let urlStr = message.fileUrl, !urlStr.isEmpty {
                            imageView(from: urlStr)
                        } else {
                            Text(displayText)
                                .font(.pretendard(.medium, size: 16))
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

                        // 시간 표시
                        Text(timeString(from: message.createdAt))
                            .font(.pretendard(.medium, size: 12))
                            .foregroundColor(.gray)
                    }

                    // 번역 버튼
                    if !message.content.isEmpty {
                        Button(action: toggleTranslateAction) {
                            Text(isTranslating ? "번역 중…" : (showTranslated ? "원문보기" : "번역하기"))
                                .font(.pretendard(.medium, size: 13))
                                .foregroundColor(.gray)
                        }
                        .disabled(isTranslating)
                    }
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

    /// 시간 문자열 포맷팅
    func timeString(from dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let isoDate = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm"
            return displayFormatter.string(from: isoDate)
        }

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

/// 날짜 헤더 정렬을 위한 Date 변환
fileprivate func headerDate(from header: String) -> Date {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "ko_KR")
    fmt.calendar = Calendar(identifier: .gregorian)
    fmt.dateFormat = "yyyy년 M월 d일 EEEE"
    if let d = fmt.date(from: header) {
        return d
    }
    let alt = DateFormatter()
    alt.locale = Locale(identifier: "en_US_POSIX")
    alt.calendar = Calendar(identifier: .gregorian)
    alt.dateFormat = "yyyy-MM-dd"
    return alt.date(from: header) ?? Date.distantPast
}

/// 파일 데이터로부터 MIME 타입 감지
fileprivate func detectMimeType(data: Data) -> String {
    if data.starts(with: [0xFF, 0xD8, 0xFF]) {
        return "image/jpeg"
    }
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
        return "image/png"
    }
    if data.starts(with: [0x47, 0x49, 0x46, 0x38]) {
        return "image/gif"
    }
    if data.count >= 12 {
        let sub = data.subdata(in: 4..<12)
        if let str = String(data: sub, encoding: .ascii), str == "ftypheic" || str == "ftypheif" {
            return "image/heic"
        }
    }
    return "application/octet-stream"
}

/// PhotosPickerItem으로부터 파일명 생성
fileprivate func suggestedFileName(for pickerItem: PhotosPickerItem, mimeType: String) -> String {
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
    switch mimeType {
    case "image/jpeg": return "image.jpg"
    case "image/png": return "image.png"
    case "image/gif": return "image.gif"
    case "image/heic": return "image.heic"
    default: return "file"
    }
}
