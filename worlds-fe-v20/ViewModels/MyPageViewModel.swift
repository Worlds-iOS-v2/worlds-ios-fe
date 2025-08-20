//
//  MyPageViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/4/25.
//

import SwiftUI

final class MyPageViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var questions: [QuestionList] = []
    @Published var userInfo: User?
    
    @MainActor
    func fetchMyInformation() async {
        do {
            let userInfo = try await UserAPIManager.shared.getUserInfo()
            self.userInfo = userInfo.userInfo
            self.errorMessage = nil
        } catch {
            print("❌  fetchMyInformation 에러 발생:", error)
            self.errorMessage = "사용자 정보를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func resetPassword(oldPassword: String, newPassword: String) async {
        do {
            let response = try await UserAPIManager.shared.resetPassword(oldPassword: oldPassword, newPassword: newPassword)
            self.errorMessage = nil
        } catch {
            print("❌ resetPassword 에러 발생:", error)
            self.errorMessage = "resetPassword에 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func fetchMyQuestions() async {
        do {
            let questions = try await UserAPIManager.shared.getMyQuestions()
            self.questions = questions
            print("\(questions)")
            self.errorMessage = nil
        } catch {
            print("❌ fetchMyQuestions 에러 발생:", error)
            self.errorMessage = "질문 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func logout() async {
        do {
            let userInfo = try await UserAPIManager.shared.logout()
            self.errorMessage = nil
        } catch {
            print("❌ logout 에러 발생:", error)
            self.errorMessage = "로그아웃에 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func deleteAccount() async {
        do {
            let userInfo = try await UserAPIManager.shared.deleteAccount()
            self.errorMessage = nil
        } catch {
            print("❌ deleteAccount 에러 발생:", error)
            self.errorMessage = "회원탈퇴에 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func updateProfileImage(with response: ProfileImageResponse) {
        guard var current = self.userInfo else { return }
        current.profileImage = response.profileImage
        current.profileImageUrl = response.profileImageUrl
        self.userInfo = current       // <- 재할당하여 퍼블리시 트리거
        self.errorMessage = nil
    }
}
