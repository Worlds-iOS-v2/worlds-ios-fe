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
    
    private let kakaoLoginManager = KakaoLoginManager()
    private let appleLoginManager = AppleLoginManager()
    
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
    
    // MARK: - 카카오 로그인
    @MainActor
    func kakaoLogin(completion: @escaping (Bool) -> Void) {
        kakaoLoginManager.loginWithKakao { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(_):
                    print("카카오 로그인 성공")
                    self.errorMessage = nil
                    completion(true)
                    
                case .failure(let error):
                    print("카카오 로그인 실패: \(error)")
                    self.errorMessage = "카카오 로그인에 실패했습니다."
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - 애플 로그인
    @MainActor
    func appleLogin(completion: @escaping (Bool) -> Void) {
        appleLoginManager.loginWithApple { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(_):
                    print("애플 로그인 성공")
                    self.errorMessage = nil
                    completion(true)
                    
                case .failure(let error):
                    print("애플 로그인 실패: \(error)")
                    self.errorMessage = "애플 로그인에 실패했습니다."
                    completion(false)
                }
            }
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
