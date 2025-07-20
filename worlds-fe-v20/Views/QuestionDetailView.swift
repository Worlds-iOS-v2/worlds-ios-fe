//
//  QuestionDetailView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
// TODO: 이미지 등록 안댄다...zz

import SwiftUI

struct QuestionDetailView: View {
    let question: QuestionList
    @State private var goToCreateCommentView = false
    @StateObject private var commentVM = CommentViewModel(preview: true)
    
    var body: some View {
        VStack(spacing: 0) {
            // 질문 정보 영역
            VStack(alignment: .leading, spacing: 15) {
                Text(question.title)
                    .font(.title)
                    .bold()
                    .padding(.top, 10)
                
                HStack {
                    Text("작성일: \(question.createdAt)")
                    Text("작성자: \(question.user.name ?? "알 수 없는 사용자")")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                Divider()
                
                Text(question.content)
                    .font(.body)
                    .padding(.vertical)
                
                Color.gray.opacity(0.1)
                    .frame(height: 13)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -20)
                
                Text("댓글 \(commentVM.comments.count)개")
                    .font(.subheadline)
                    .bold()
                    .padding(.bottom, 5)
            }
            .padding(.top, 10)
            
            // 댓글 리스트
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    if commentVM.comments.isEmpty {
                        Text("아직 답변이 없습니다.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(commentVM.replies(for: nil)) { comment in
                            CommentRow(comment: comment, depth: 0, allComments: commentVM.comments)
                        }
                    }
                }
                .padding(.top, 10)
            }
            
            // 댓글 입력창
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
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .onAppear {
            Task {
                do {
                    self.commentVM.comments = try await APIService.shared.fetchComments(for: question.id)
                } catch {
                    print("답변 로딩 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    let vm = QuestionViewModel()
    vm.loadDummyData()
    
    let commentVM = CommentViewModel(preview: true)
    
    return QuestionDetailView(
        question: vm.questions.first!
    )
    .environmentObject(commentVM)
}
