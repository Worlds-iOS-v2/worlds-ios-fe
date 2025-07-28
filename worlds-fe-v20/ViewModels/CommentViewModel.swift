//
//  CommentViewModel.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 7/20/25.
//

import Foundation
import Alamofire

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var newComment: String = ""
    @Published var isLoading: Bool = false
    @Published var replyingTo: Int? = nil // 현재 답글 입력 중인 댓글 ID
    @Published var replyContent: String = ""
    @Published var likes: [Int: CommentLike] = [:] // 좋아요 상태 관리용
    @Published var errorMessage: String?
    
    init() {}
    
    // 댓글 데이터 초기화
    func resetComments() {
        comments = []
        newComment = ""
        isLoading = false
        replyingTo = nil
        replyContent = ""
        likes = [:]
        errorMessage = nil
        print("🔄 댓글 데이터 초기화 완료")
    }
    
    // 계층 구조로 정리하는 함수
    func replies(for parentId: Int?) -> [Comment] {
        return comments.filter { $0.parentId == parentId }
    }

    // 댓글 작성
    func submitComment(for questionId: Int, parentId: Int? = nil) async {
        print("🟡 댓글 등록 시작")
                print("📩 입력 상태 - newComment: '\(newComment)', replyContent: '\(replyContent)', parentId: \(parentId?.description ?? "nil")")
        let content: String
            if let parentId = parentId {
                content = replyContent.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
            }


        guard !content.isEmpty else {
            print("내용이 비어 있어 댓글을 등록하지 않음")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // 서버에 댓글 또는 대댓글 전송
            let success = try await APIService.shared.postComment(
                content: content,
                questionId: questionId,
                parentId: parentId
            )

            print("댓글 등록 API 응답: \(success)")

            if success {
                // 입력 필드 초기화
                self.newComment = ""
                self.replyContent = ""
                self.replyingTo = nil

                // 댓글 갱신
                await fetchComments(for: questionId)
            } else {
                self.errorMessage = "댓글 등록에 실패했습니다."
                print("댓글 등록 실패: 서버에서 false 반환")
            }
        } catch {
            self.errorMessage = "댓글 등록 중 오류 발생"
            print("댓글 작성 실패: \(error.localizedDescription)")
            if let afError = error as? AFError {
                print("AFError 디버그 정보: \(afError)")
            }
        }
    }
    
    // 댓글 불러오기
    func fetchComments(for questionId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await APIService.shared.fetchComments(for: questionId)
            self.comments = result
            
            print("서버에서 받아온 댓글: \(result.map { $0.content })")
            
            // 댓글별 좋아요 정보 동기화
            for comment in result {
                let count = try await APIService.shared.fetchCommentLike(commentId: comment.id)
                DispatchQueue.main.async {
                    self.likes[comment.id] = count
                }
            }
        } catch {
            self.errorMessage = "댓글을 불러오지 못했습니다."
            print("댓글 조회 실패: \(error.localizedDescription)")
        }
    }
    
    // 댓글 삭제
    func deleteComment(_ commentId: Int, for questionId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let success = try await APIService.shared.deleteComment(commentId: commentId)
            if success {
                self.comments.removeAll { $0.id == commentId }
                await fetchComments(for: questionId)
            } else {
                self.errorMessage = "댓글 삭제 실패"
            }
        } catch {
            self.errorMessage = "댓글 삭제 중 오류 발생"
            print("삭제 오류: \(error.localizedDescription)")
        }
    }
    
    func toggleLike(for commentId: Int) {
        Task {
            do {
                // 좋아요 토글 API 호출 → count + isLiked 정보 반환
                let updatedLike = try await APIService.shared.toggleCommentLike(commentId: commentId)
                DispatchQueue.main.async {
                    self.likes[commentId] = updatedLike
                }
            } catch {
                print("좋아요 토글 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 좋아요 눌렀는지 여부
    func fetchLikeStatus(for commentId: Int) async {
        do {
            let isLiked = try await APIService.shared.fetchIsLiked(commentId: commentId)
            let count = try await APIService.shared.fetchLikeCount(commentId: commentId) // count API도 호출

            likes[commentId] = CommentLike(id: commentId, count: count, isLiked: isLiked)
        } catch {
            print("좋아요 상태 조회 실패: \(error.localizedDescription)")
        }
    }
}
