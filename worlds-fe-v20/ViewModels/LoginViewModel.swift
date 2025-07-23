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
    func login() async {
        do {
            let user = try await UserAPIManager.shared.login(email: email, password: password)
            print("로그인 정보: \(user)")
            self.errorMessage = nil
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print(message)
        } catch {
            self.errorMessage = "로그인 실패: \(error.localizedDescription)"
            print(errorMessage)
        }
    }
}
