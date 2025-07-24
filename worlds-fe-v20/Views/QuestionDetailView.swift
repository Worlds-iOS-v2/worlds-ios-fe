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
    @EnvironmentObject var commentVM: CommentViewModel

    @State private var showOptions = false
    @State private var showReportReasons = false
    @ObservedObject var viewModel: QuestionViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss

    let reportReasons: [(label: String, value: ReportReason)] = [
        ("비속어", .offensive),
        ("음란", .sexual),
        ("광고", .ad),
        ("기타", .etc)
    ]

    let badgeColorMap: [String: Color] = [
        "학습": .blue,
        "자유": .purple,
        "전체": .gray
    ]

    var body: some View {
        VStack(spacing: 0) {
            if let question = questionDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(question.category.displayName)
                                .font(.subheadline)
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
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 38, height: 38)
                                .foregroundColor(.gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(question.user.name)
                                    .font(.callout)
                                    .fontWeight(.bold)
                                Text(formatDate(question.createdAt))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        Text(question.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 24)
                            .padding(.horizontal)

                        Text(question.content)
                            .font(.body)
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
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                        }

                        Button("번역하기") {}
                            .font(.callout)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                            .padding(.top, 14)

                        Color.gray.opacity(0.1)
                            .frame(height: 13)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, -20)

                        Text("댓글 \(commentVM.comments.count)개")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 12)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            if commentVM.comments.isEmpty {
                                Text("아직 답변이 없습니다.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                            } else {
                                ForEach(commentVM.replies(for: nil)) { comment in
                                    CommentRow(comment: comment, depth: 0, allComments: commentVM.comments)
                                        .environmentObject(commentVM)
                                }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }

                Divider()

                HStack {
                    TextField("댓글을 입력하세요", text: $commentVM.replyContent)
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.brown, lineWidth: 1)
                        )

                    Button(action: {
                        Task {
                            await commentVM.submitComment(
                                for: question.id,
                                parentId: commentVM.replyingTo
                            )
                        }
                    }) {
                        Text("등록")
                            .frame(minWidth: 60)
                            .padding(.vertical, 12)
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.leading, 8)
                }
                .padding()
                .background(Color.white)
            } else {
                ProgressView()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            Task {
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
            Button("삭제", role: .destructive) {
                Task {
                    try await viewModel.deleteQuestion(id: questionId)
                    await MainActor.run {
                        dismiss()
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
