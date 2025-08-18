//
//  ResetPasswordViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/14/25.
//

import SwiftUI

final class ResetPasswordViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    // 로그인 함수
    @MainActor
    func login(email: String, password: String) async -> Bool {
        
        // 로그인 진행 전 기존 사용자 정보 삭제.
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        
        do {
            let user = try await UserAPIManager.shared.login(email: email, password: password)
            print("로그인 정보: \(user)")
            self.errorMessage = nil
            
            return true
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("서버 에러: \(message)")
            
            return false
        } catch {
            if error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                self.errorMessage = "접근이 제한되었습니다. 관리자에게 문의하세요."
            }
            print("기타 에러: \(errorMessage)")
            
            return false
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
}
