//
//  CommentRowView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 7/21/25.
//

import SwiftUI
import Translation

@available(iOS 18.0, *)
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
    
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var translatedText: String?
    @State private var isTranslating = false

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
                        Text("|  \(formatDate(comment.createdAt))")
                            .font(.caption2)
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
                            } else {
                                Button {
                                    showReportSheet = true
                                } label: {
                                    Label("신고하기", systemImage: "exclamationmark.bubble")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(90))
                        }
                    }

                    // 본문
                    VStack(alignment: .leading){
                        HStack(alignment: .top, spacing: 4) {
                            if depth > 0 {
                                Image(systemName: "arrow.turn.down.right")
                                    .foregroundColor(.gray)
                            }
                            
                            Text(comment.content)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let translated = translatedText {
                            Text(translated)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
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

                        HStack{
                            // 답글 달기 버튼
                            Button(action: {
                                commentVM.replyingTo = (commentVM.replyingTo == comment.id) ? nil : comment.id
                                commentVM.replyContent = ""
                            }) {
                                Text(commentVM.replyingTo == comment.id ? "답글 취소" : "답글 달기")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            // 번역 버튼 토글 로직
                            if isTranslating {
                                Button(action: {}) {
                                    Text("번역 중...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .disabled(true)
                            } else if translatedText != nil {
                                Button(action: {
                                    // 번역 취소: 번역문 및 관련 상태 리셋
                                    translatedText = nil
                                    isTranslating = false
                                    translationConfiguration = nil
                                }) {
                                    Text("번역취소")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Button(action: {
                                    if !isTranslating { startTranslation() }
                                }) {
                                    Text("번역하기")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
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
                    .environmentObject(commentVM)
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
        .translationTask(translationConfiguration) { session in
            await performTranslation(using: session)
                    }
    }
    
    // 번역 시작 함수
    func startTranslation() {
        let targetLang = Locale.current.language.languageCode?.identifier ?? "en"
        translationConfiguration = TranslationSession.Configuration(
            source: nil, // 원문 언어 자동 감지
            target: Locale.Language(identifier: targetLang)
        )
        isTranslating = true
        translatedText = nil
    }
    
    // 번역 실행 함수
    func performTranslation(using session: TranslationSession) async {
        guard let config = translationConfiguration else { return }
        do {
            let response = try await session.translate(comment.content)
            translatedText = response.targetText
        } catch {
            translatedText = "번역 실패: \(error.localizedDescription)"
        }
        isTranslating = false
        translationConfiguration = nil // 다시 버튼 누를 때만 번역
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
