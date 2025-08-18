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
            if error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                self.errorMessage = "접근이 제한되었습니다. 관리자에게 문의하세요."
            }
            print("기타 에러: \(errorMessage)")
            
            return false
        }
    }
    
    @MainActor
    func attendanceCheck() async -> Bool {
        do {
            let _ = try await UserAPIManager.shared.attendanceCheck()
            self.errorMessage = nil
            
            return true
        } catch UserAPIError.serverError(let message) {
            self.errorMessage = message
            print("서버 에러: \(message)")
            
            return false
        } catch {
            if error.localizedDescription == "The data couldn’t be read because it isn’t in the correct format." {
                self.errorMessage = "출석체크가 되지 않았습니다."
            }
            print("기타 에러: \(errorMessage)")
            
            return false
        }
    }
}
