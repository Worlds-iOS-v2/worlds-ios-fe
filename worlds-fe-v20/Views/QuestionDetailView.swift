//
//  QuestionDetailView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//

//  TODO: 이미지 백딴 전송, 삭제하면 바로 창 닫히게

import SwiftUI

struct QuestionDetailView: View {
    let question: QuestionList

    @State private var goToCreateAnswerView = false
    @StateObject private var commentVM = CommentViewModel(preview: true)
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
            // 상단 ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // 카테고리 뱃지 + 옵션 버튼
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

                    // 유저 정보
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

                    // 제목
                    Text(question.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 24)
                        .padding(.horizontal)

                    // 본문
                    Text(question.content)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.top, 18)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)

                    // 번역 버튼
                    Button("번역하기") {
                        // 번역 기능
                    }
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

                    // 댓글 리스트
                    VStack(alignment: .leading, spacing: 15) {
                        if commentVM.comments.isEmpty {
                            Text("아직 답변이 없습니다.")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.top, 10)
                        } else {
                            ForEach(commentVM.replies(for: nil)) { comment in
                                CommentRow(comment: comment, depth: 0, allComments: commentVM.comments)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal)
                }
                .padding(.top, 10)
            }

            Divider()

            // 댓글 입력창 (항상 하단 고정)
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
//             .padding(.top, 10)
//         }
//         .padding(.horizontal, 20)
//         .padding(.bottom, 20)
            .padding()
            .background(Color.white)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 키보드 올라올 때 대응
        .onAppear {
            Task {
                await commentVM.fetchComments(for: question.id)
            }
        }
        // 네비게이션
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
        // 옵션 다이얼로그
        .confirmationDialog("옵션", isPresented: $showOptions, titleVisibility: .visible) {
            Button("신고") {
                showReportReasons = true
            }
            Button("삭제", role: .destructive) {
                Task {
                    try await viewModel.deleteQuestion(id: question.id)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
            Button("취소", role: .cancel) {}
        }
        // 신고 사유 다이얼로그
        .confirmationDialog("신고 사유를 선택하세요", isPresented: $showReportReasons, titleVisibility: .visible) {
            ForEach(reportReasons, id: \.value) { reason in
                Button(reason.label) {
                    Task {
                        try? await viewModel.reportQuestion(questionId: question.id, reason: reason.value)
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
