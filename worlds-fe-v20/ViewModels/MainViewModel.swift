//
//  MainViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var posts: [QuestionList] = []

    func getUsername() -> String {
        guard let username = UserDefaults.standard.string(forKey: "username") else {
            return "사용자 이름을 불러올 수 없습니다."
        }
        return username
    }
    
    @MainActor
    func fetchLatestPosts() async {
        do {
            let posts = try await APIService.shared.fetchQuestions()
            self.posts = posts
            self.errorMessage = nil
        } catch {
            print("❌ 에러 발생:", error)
            self.errorMessage = "질문 최신 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
}
