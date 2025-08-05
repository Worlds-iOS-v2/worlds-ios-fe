//
//  OCRViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/30/25.
//

import SwiftUI

final class OCRViewModel: ObservableObject {
    @Published var originalText: [String] = []
    @Published var translatedText: [String] = []
    @Published var keyConcept: String = ""
    @Published var solution: String = ""
    @Published var summary: String = ""

    @Published var errorMessage: String?
    
    // 로딩 상태 추가
    @Published var isOCRLoading: Bool = false
    @Published var isSummaryLoading: Bool = false
    
    // Summary 데이터 캐싱을 위한 플래그
    private var hasSummaryData: Bool = false
    
    @MainActor
    func fetchOCR(selectedImage: UIImage) async throws {
        isOCRLoading = true
        errorMessage = nil
        
        // 1. UIImage를 Data로 변환
        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            print("이미지를 Data로 변환 실패")
            isOCRLoading = false
            return
        }
        
        do {
            let result = try await UserAPIManager.shared.OCRTranslation(file: imageData)
            print("OCR 정보: \(result)")
            
            // 서버 응답에서 텍스트 배열들을 가져와서 할당
            self.originalText = result.originalText
            self.translatedText = result.translatedText
            self.errorMessage = nil
            
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("서버 에러: \(message)")
            
        } catch {
            self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            print("기타 에러: \(errorMessage)")
            
        }
        
        isOCRLoading = false
    }
    
    @MainActor
    func fetchOCRSolution() async throws {
        // 이미 데이터가 있으면 다시 가져오지 않음
        if hasSummaryData {
            return
        }
        
        isSummaryLoading = true
        errorMessage = nil
        
        do {
            let result = try await UserAPIManager.shared.OCRSummary()
            print("OCRSummary 정보: \(result)")

            self.keyConcept = result.keyConcept
            self.solution = result.solution
            self.summary = result.summary
            
            // 데이터를 성공적으로 가져왔으므로 플래그 설정
            self.hasSummaryData = true
            self.errorMessage = nil
            
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("서버 에러: \(message)")
            
        } catch {
            self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            print("기타 에러: \(errorMessage)")
            
        }
        
        isSummaryLoading = false
    }
    
    // Summary 데이터 초기화 (새로운 OCR을 시작할 때 호출)
    func resetSummaryData() {
        hasSummaryData = false
        keyConcept = ""
        solution = ""
        summary = ""
    }
    
    // 질문 작성
    @MainActor
    func createQuestion(title: String, content: String, category: String, images: [UIImage]? = nil) async throws {
        let imageData = images?.compactMap { $0.jpegData(compressionQuality: 0.7) } ?? []
        
        do {
            let result = try await APIService.shared.createQuestion(title: title, content: content, category: category, images: imageData)
            print("OCRSummary 정보: \(result)")

            self.errorMessage = nil
            
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("서버 에러: \(message)")
            
        } catch {
            self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            print("기타 에러: \(errorMessage)")
        }
    }
}
