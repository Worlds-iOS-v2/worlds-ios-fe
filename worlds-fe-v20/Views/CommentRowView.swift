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
    @State private var showReportSheet = false
    @State private var selectedReason: ReportReason?
    @State private var showEtcInput = false
    @State private var etcReasonText = ""
    @State private var showReportResultAlert = false
    @State private var reportResultMessage = ""

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

                        // 메뉴
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
                                showReportSheet = true
                            } label: {
                                Label("신고하기", systemImage: "exclamationmark.bubble")
                            }

                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(90))
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

                        // 답글 달기 버튼
                        Button(action: {
                            commentVM.replyingTo = (commentVM.replyingTo == comment.id) ? nil : comment.id
                            commentVM.replyContent = ""
                        }) {
                            Text(commentVM.replyingTo == comment.id ? "답글 취소" : "답글 달기")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(isReplyingTarget ? Color.gray.opacity(0.1) : Color.clear)

            // 재귀적으로 대댓글 표시
            ForEach(replies) { reply in
                CommentRow(comment: reply, depth: depth + 1, allComments: allComments)
            }
        }
        // 신고 사유 선택 다이얼로그
        .confirmationDialog("신고 사유를 선택하세요", isPresented: $showReportSheet, titleVisibility: .visible) {
            ForEach(ReportReason.allCases, id: \.self) { reason in
                Button(reason.label) {
                    if reason == .etc {
                        selectedReason = .etc
                        showEtcInput = true
                    } else {
                        Task {
                            await sendReport(reason: reason.rawValue)
                        }
                    }
                }
            }
        }
        // 기타 입력창 알럿
        .alert("기타 사유 입력", isPresented: $showEtcInput) {
            TextField("기타 신고 사유", text: $etcReasonText)
            Button("신고하기") {
                Task {
                    await sendReport(reason: "etc", etcReason: etcReasonText)
                }
            }
            Button("취소", role: .cancel) {
                etcReasonText = ""
            }
        } message: {
            Text("기타 사유를 입력해 주세요.")
        }
        // 신고 결과 알림
        .alert(reportResultMessage, isPresented: $showReportResultAlert) {
            Button("확인", role: .cancel) {}
        }
    }

    // 신고 전송 함수
    func sendReport(reason: String, etcReason: String? = nil) async {
        do {
            try await APIService.shared.reportComment(
                commentId: comment.id,
                reason: reason,
                etcReason: etcReason,
                questionId: comment.questionId
            )
            reportResultMessage = "신고가 접수되었습니다."
        } catch {
            reportResultMessage = "신고에 실패했습니다: \(error.localizedDescription)"
        }
        etcReasonText = ""
        showReportResultAlert = true
    }
}
