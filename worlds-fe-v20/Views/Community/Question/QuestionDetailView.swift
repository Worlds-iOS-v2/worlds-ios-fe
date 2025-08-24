//
//  QuestionDetailView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//

//  TODO: 삭제하면 바로 창 닫히게

import SwiftUI

struct QuestionDetailView: View {
    let questionId: Int

    @State private var questionDetail: QuestionDetail?
    @State private var goToCreateAnswerView = false
    @StateObject private var commentVM = CommentViewModel()

    @State private var showOptions = false
    @State private var showReportReasons = false
    @ObservedObject var viewModel: QuestionViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss

    @FocusState private var isTextFieldFocused: Bool

    @State private var translatedTitle: String?
    @State private var translatedContent: String?

    @State private var isImageViewerPresented: Bool = false
    @State private var selectedImageURL: URL? = nil
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero

    let reportReasons: [(label: String, value: ReportReason)] = [
        ("비속어", .offensive),
        ("음란", .sexual),
        ("광고", .ad),
        ("기타", .etc)
    ]

    let badgeColorMap: [String: Color] = [
        "학습": .mainws,
        "자유": .purple,
        "전체": .gray
    ]
    
    let profileImages: [String] = ["himchan", "doran", "malgeum", "saengak"]
    
    private var userProfileImage: String {
        guard let question = questionDetail else { return "himchan" }
        let index = abs(question.user.id.hashValue) % profileImages.count
        return profileImages[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let question = questionDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(question.category.displayName)
                                .font(.pretendard(.bold, size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(badgeColorMap[question.category.displayName] ?? .gray)
                                .cornerRadius(16)

                            Spacer()

                            Button {
                                showOptions = true
                            } label: {
                                Image(systemName: "ellipsis")
                                    .rotationEffect(.degrees(90))
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                        HStack(spacing: 10) {
                            
                            // 학생이면 랜덤 이미지
                            if let isTeacher = question.user.role {
                                if isTeacher {
                                    Image("default")
                                        .resizable()
                                        .frame(width: 38, height: 38)
                                } else {
                                    Image("\(userProfileImage)")
                                        .resizable()
                                        .frame(width: 38, height: 38)
                                }
                            } else {
                                Image("default")
                                    .resizable()
                                    .frame(width: 38, height: 38)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(question.user.name)
                                    .font(.pretendard(.semiBold, size: 15))
                                    .fontWeight(.bold)
                                
                                Text(formatDate(question.createdAt))
                                    .font(.pretendard(.medium, size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)

                        Text(translatedTitle ?? question.title)
                            .font(.pretendard(.bold, size: 24))
                            .padding(.top, 24)
                            .padding(.horizontal)

                        Text(translatedContent ?? question.content)
                            .font(.pretendard(.medium, size: 18))
                            .foregroundColor(.black)
                            .padding(.top, 18)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)

                        if let imageUrls = question.imageUrls, !imageUrls.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(imageUrls, id: \.self) { urlString in
                                        if let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 220, height: 160)
                                                        .clipped()
                                                        .cornerRadius(10)
                                                case .failure:
                                                    Image(systemName: "xmark.octagon")
                                                        .foregroundColor(.red)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .onTapGesture {
                                                selectedImageURL = url
                                                isImageViewerPresented = true
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                        }

                        Button("번역하기") {
                            guard let question = questionDetail else { return }

                            let targetLang = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"

                            if targetLang == "ko" {
                                self.translatedTitle = question.title
                                self.translatedContent = question.content
                                return
                            }

                            // ✅ JWT 헤더 포함 + source 자동감지로 호출
                            APIService.shared.translateText(text: question.title, source: "auto", target: targetLang) { translated in
                                DispatchQueue.main.async {
                                    self.translatedTitle = translated
                                }
                            }

                            APIService.shared.translateText(text: question.content, source: "auto", target: targetLang) { translated in
                                DispatchQueue.main.async {
                                    self.translatedContent = translated
                                }
                            }
                        }
                        .font(.pretendard(.semiBold, size: 16))
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                        .padding(.vertical, 14)

                        Color.gray.opacity(0.1)
                            .frame(height: 13)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, -20)

                        Text("댓글 \(commentVM.comments.count)개")
                            .font(.pretendard(.semiBold, size: 16))
                            .bold()
                            .padding(.top, 12)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            if commentVM.comments.isEmpty {
                                Text("아직 답변이 없습니다.")
                                    .font(.pretendard(.semiBold, size: 16))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                            } else {
                                ForEach(commentVM.replies(for: nil)) { comment in
                                    if #available(iOS 18.0, *) {
                                        CommentRow(comment: comment, depth: 0, allComments: commentVM.comments)
                                            .environmentObject(commentVM)
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 10)
                // 키보드 내리기 위한 탭 제스처
                .simultaneousGesture(
                    TapGesture().onEnded {
                        isTextFieldFocused = false
                    }
                )
                Divider()

                // 댓글 입력창 (항상 하단 고정)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        TextField(
                            "댓글을 입력하세요",
                            text: commentVM.replyingTo == nil ? $commentVM.newComment : $commentVM.replyContent
                        )
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.mainws, lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)

                        Button(action: {
                            Task {
                                await commentVM.submitComment(
                                    for: questionId,
                                    parentId: commentVM.replyingTo // nil이면 일반 댓글
                                )
                                isTextFieldFocused = false
                            }
                        }) {
                            Text("등록")
                                .font(.pretendard(.bold, size: 16))
                                .frame(minWidth: 60)
                                .padding(.vertical, 12)
                                .background(Color.mainws)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color.white)
                }
                .fullScreenCover(isPresented: $isImageViewerPresented) {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        if let url = selectedImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    GeometryReader { proxy in
                                        let magnify = MagnificationGesture()
                                            .onChanged { value in
                                                // value is relative to the start of this gesture
                                                let relative = value / lastZoomScale
                                                var newScale = zoomScale * relative
                                                newScale = min(max(newScale, 1.0), 4.0) // clamp 1x ~ 4x
                                                zoomScale = newScale
                                                lastZoomScale = value
                                            }
                                            .onEnded { _ in
                                                lastZoomScale = 1.0
                                            }
                                        let drag = DragGesture()
                                            .onChanged { gesture in
                                                guard zoomScale > 1.0 else { return }
                                                dragOffset = CGSize(
                                                    width: accumulatedOffset.width + gesture.translation.width,
                                                    height: accumulatedOffset.height + gesture.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                accumulatedOffset = dragOffset
                                            }

                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .scaleEffect(zoomScale)
                                            .offset(dragOffset)
                                            .frame(width: proxy.size.width, height: proxy.size.height)
                                            .background(Color.black)
                                            .ignoresSafeArea()
                                            .gesture(drag)
                                            .gesture(magnify)
                                            .onTapGesture(count: 2) {
                                                if zoomScale > 1.0 {
                                                    // reset
                                                    zoomScale = 1.0
                                                    dragOffset = .zero
                                                    accumulatedOffset = .zero
                                                } else {
                                                    zoomScale = 2.0
                                                }
                                            }
                                    }
                                case .failure:
                                    VStack(spacing: 12) {
                                        Image(systemName: "xmark.octagon")
                                            .foregroundColor(.red)
                                        Text("이미지를 불러오지 못했습니다")
                                            .foregroundColor(.white)
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        // 닫기 버튼
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    isImageViewerPresented = false
                                    zoomScale = 1.0
                                    dragOffset = .zero
                                    accumulatedOffset = .zero
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(12)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                // 댓글 데이터 초기화 - @StateObject는 재사용되므로 필요
                commentVM.resetComments()

                await viewModel.fetchQuestionDetail(questionId: questionId)
                self.questionDetail = viewModel.selectedQuestion
                await commentVM.fetchComments(for: questionId)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
        }
        .confirmationDialog("옵션", isPresented: $showOptions, titleVisibility: .visible) {
            Button("신고") {
                showReportReasons = true
            }
            let currentUserId = UserDefaults.standard.integer(forKey: "userId")
            if (questionDetail?.user.id ?? -1) == currentUserId {
                Button("삭제", role: .destructive) {
                    Task {
                        try await viewModel.deleteQuestion(id: questionId)
                        await MainActor.run {
                            viewModel.questions.removeAll { $0.id == questionId }
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("신고 사유를 선택하세요", isPresented: $showReportReasons, titleVisibility: .visible) {
            ForEach(reportReasons, id: \.value) { reason in
                Button(reason.label) {
                    Task {
                        try? await viewModel.reportQuestion(questionId: questionId, reason: reason.value)
                    }
                }
            }
            Button("취소", role: .cancel) {}
        }
    }

    // 날짜 포맷터
    func formatDate(_ dateStr: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        if let date = inputFormatter.date(from: dateStr) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            return formatter.string(from: date)
        }
        return dateStr.prefix(10) + " " + dateStr.dropFirst(11).prefix(5)
    }
}

