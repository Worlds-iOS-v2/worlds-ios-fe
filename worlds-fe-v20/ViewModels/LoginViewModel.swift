//
//  LoginViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/21/25.
//

import SwiftUI

final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var errorMessage: String?
    
    // 로그인 함수
    @MainActor
    func login() async -> Bool {
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
            self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            print("기타 에러: \(errorMessage)")
            
            return false
        }
    }
}
