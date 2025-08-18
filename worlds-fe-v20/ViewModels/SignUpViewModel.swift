//
//  SignUpViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

final class SignUpViewModel: ObservableObject {
    @Published var isMentor: Bool = false
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var birthDate: String = ""
    @Published var mentorCode: String?
    
    @Published var errorMessage: String?
    
    // 회원가입 함수
    @MainActor
    func signup() async -> Bool {
        do {
            let user = try await UserAPIManager.shared.signUp(name: name, email: email, password: password, birth: birthDate, isMentor: isMentor, mentorCode: mentorCode)
            print("회원 가입 정보: \(user)")
            self.errorMessage = nil
            
            return true
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("이메일 중복 에러 메세지. \(message)")

            return false
        } catch {
            if error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                self.errorMessage = "접근이 제한되었습니다. 관리자에게 문의하세요."
            }
            
            return false
        }
    }
    
    // 이메일 인증
    @MainActor
    func checkEmail() async -> Bool {
        do {
            let _ = try await UserAPIManager.shared.emailCheck(email: email)
            
            return true
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("이메일 인증 에러 메세지. \(message)")
            
            return false
        } catch {
            if error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                self.errorMessage = "접근이 제한되었습니다. 관리자에게 문의하세요."
            }
            
            return false
        }
    }
    
    @MainActor
    func verifyEmailCode(email: String, code: String) async -> Bool {
        do {
            let _ = try await UserAPIManager.shared.emailVerifyCode(email: email, verifyCode: code)
            
            return true
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print(message)
            
            return false
        } catch {
            if error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                self.errorMessage = "접근이 제한되었습니다. 관리자에게 문의하세요."
            }
            
            return false
        }
    }
}
