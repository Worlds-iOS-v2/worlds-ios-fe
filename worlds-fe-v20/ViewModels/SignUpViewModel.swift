//
//  SignUpViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

final class SignUpViewModel: ObservableObject {
//    @Published var role: UserRole = .none
    @Published var isMentor: Bool = false
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
//    @Published var phoneNumber: String = ""
    @Published var birthDate: String = ""
    @Published var mentorCode: String?
    
    @Published var errorMessage: String?
    
    // 회원가입 함수
    @MainActor
    func signup() async {
        do {
            print("email: \(email), password: \(password)")
            let user = try await UserAPIManager.shared.signUp(name: name, email: email, password: password, birth: birthDate, isMentor: isMentor, mentorCode: mentorCode)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // 이메일 인증
    func checkEmail() async {
        do {
            let user = try await UserAPIManager.shared.emailCheck(email: email)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
