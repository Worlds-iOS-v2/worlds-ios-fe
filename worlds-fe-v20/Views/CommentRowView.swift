//
//  CommentRowView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 7/21/25.
//

import SwiftUI

struct CommentRow: View {
    let comment: Comment
    let depth: Int
    let allComments: [Comment]
    let currentUserId = UserDefaults.standard.integer(forKey: "userId")
    
    @State private var showDeleteConfirm = false
    @State private var showReportAlert = false
    @EnvironmentObject var commentVM: CommentViewModel

    var replies: [Comment] {
        allComments.filter { $0.parentId == comment.id }
    }
    
    var isReplyingTarget: Bool {
        commentVM.replyingTo == comment.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // depth 만큼 들여쓰기
                Spacer().frame(width: CGFloat(depth) * 16)

                VStack(alignment: .leading, spacing: 5) {
                    // 유저 정보 및 날짜
                    HStack(spacing: 5) {
                        Text(comment.user.userName)
                            .font(.subheadline)
                            .bold()
                        
                        if comment.user.isMentor {
                            Text("멘토")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Text("| \(comment.createdAt)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        // 메뉴 (삭제 / 신고)
                        Menu {
                            if comment.user.id == currentUserId {
                                Button(role: .destructive) {
                                    Task {
                                        await commentVM.deleteComment(comment.id, for: comment.questionId)
                                    }
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                            
                            Button {
                                showReportAlert = true
                            } label: {
                                Label("신고하기", systemImage: "exclamationmark.bubble")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(90))
                        }
                        .alert("신고가 접수되었습니다.", isPresented: $showReportAlert) {
                            Button("확인", role: .cancel) { }
                        }
                    }

                    // 본문
                    HStack(alignment: .top, spacing: 4) {
                        if depth > 0 {
                            Image(systemName: "arrow.turn.down.right")
                                .foregroundColor(.gray)
                        }
                        
                        Text(comment.content)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // 좋아요 + 답글 달기
                    HStack(spacing: 12) {
                        // 좋아요 UI
                        HStack(spacing: 4) {
                            Button(action: {
                                commentVM.toggleLike(for: comment.id)
                            }) {
                                Image(systemName: commentVM.likes[comment.id]?.isLiked == true ? "heart.fill" : "heart")
                                    .foregroundColor(.red)
                            }
                            Text("\(commentVM.likes[comment.id]?.count ?? 0)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // 답글 달기 / 취소 버튼
                        Button(action: {
                            commentVM.replyingTo = (commentVM.replyingTo == comment.id) ? nil : comment.id
                            commentVM.replyContent = ""
                        }) {
                            Text(commentVM.replyingTo == comment.id ? "답글 취소" : "답글 달기")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(isReplyingTarget ? Color.gray.opacity(0.1) : Color.clear)

            // 재귀적으로 대댓글 렌더링
            ForEach(replies) { reply in
                CommentRow(comment: reply, depth: depth + 1, allComments: allComments)
            }
        }
    }
}

#Preview {
    let vm = CommentViewModel(preview: true)
    return CommentRow(
        comment: vm.comments.first!, // 루트 댓글
        depth: 0,
        allComments: vm.comments
    )
    .environmentObject(vm)
}
