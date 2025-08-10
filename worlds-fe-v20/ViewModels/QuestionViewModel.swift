//
//  QuestionViewModel.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//

import Foundation
import UIKit

@MainActor
class QuestionViewModel: ObservableObject {
    @Published var questions: [QuestionList] = []
    @Published var selectedQuestion: QuestionDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var thumbnails: [Int: String] = [:] // questionId : first attachment URL

    // 질문 목록 조회
    func fetchQuestions() async {
        isLoading = true
        do {
            let list = try await APIService.shared.fetchQuestions()
            self.questions = list
            // 목록 첫 화면용 썸네일 프리패치 (상세에서 첫 이미지만 가져오기)
            let ids = list.prefix(20).map { $0.id }
            Task { await self.loadThumbnails(for: ids) }
            self.errorMessage = nil
        } catch {

            print("❌ 에러 발생:", error)
            self.errorMessage = "질문 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    // 질문 상세 조회
    func fetchQuestionDetail(questionId: Int) async {
        isLoading = true
        do {
            let detail = try await APIService.shared.fetchQuestionDetail(questionId: questionId)
            selectedQuestion = detail
            errorMessage = nil
        } catch {
            errorMessage = "질문 상세 불러오기에 실패했습니다: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // 질문 작성
    func createQuestion(title: String, content: String, category: String, images: [UIImage]? = nil) async throws {
        isLoading = true
        defer { isLoading = false }

        let imageData = images?.compactMap { $0.jpegData(compressionQuality: 0.7) } ?? []

        let success = try await APIService.shared.createQuestion(
            title: title,
            content: content,
            category: category,
            images: imageData
        )

        if success {
            errorMessage = nil
            await fetchQuestions()
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "질문 등록에 실패했습니다."])
        }
    }

    // 질문 삭제
    func deleteQuestion(id: Int) async throws {
        isLoading = true
        defer { isLoading = false }

        let success = try await APIService.shared.deleteQuestion(questionId: id)
        if success {
            errorMessage = nil
            if let idx = questions.firstIndex(where: { $0.id == id }) {
                questions.remove(at: idx)
            }
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "질문 삭제에 실패했습니다."])
        }
    }
    
    // 질문 신고
    func reportQuestion(
            questionId: Int,
            reason: ReportReason,
            etcReason: String? = nil
        ) async throws {
            isLoading = true
            defer { isLoading = false }

            do {
                let success = try await APIService.shared.reportQuestion(
                    questionId: questionId,
                    reason: reason,
                    etcReason: etcReason
                )
                if success {
                    errorMessage = nil
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "질문 신고에 실패했습니다."])
                }
            } catch {
                errorMessage = "질문 신고 실패: \(error.localizedDescription)"
                throw error
            }
        }
    
    // 단건 썸네일 로드 (필요 시)
    func loadThumbnailIfNeeded(for id: Int) async {
        if thumbnails[id] != nil { return }
        do {
            if let urls = try await APIService.shared.fetchQuestionAttachments(questionId: id), let first = urls.first {
                thumbnails[id] = first
            }
        } catch {
            // 실패시 무시
        }
    }

    // 여러 건 동시 로드
    func loadThumbnails(for ids: [Int]) async {
        await withTaskGroup(of: (Int, String?).self) { group in
            for id in ids where thumbnails[id] == nil {
                group.addTask {
                    do {
                        let urls = try await APIService.shared.fetchQuestionAttachments(questionId: id)
                        return (id, urls?.first)
                    } catch {
                        return (id, nil)
                    }
                }
            }
            for await (id, url) in group {
                if let url { thumbnails[id] = url }
            }
        }
    }
}
