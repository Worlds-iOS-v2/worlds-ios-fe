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
    
    // 회원가입 함수
    @MainActor
    func login() async {
        do {
            // print("email: \(email), password: \(password)")
            let user = try await UserAPIManager.shared.login(email: email, password: password)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
