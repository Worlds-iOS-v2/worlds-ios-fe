//
//  AppState.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/8/25.
//

import SwiftUI

enum AppFlowState {
    case launch
    case login
    case signUp
    case main
}

final class AppState: ObservableObject {
    @Published var flow: AppFlowState = .launch
    
    func autoLogin() async {
        // 저장된 리프레시토큰이 없으면 로그인 화면.
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            DispatchQueue.main.async { self.flow = .login }
            return
        }
        
        do {
            let _ = try await UserAPIManager.shared.getNewAccessToken()
            let _ = try await UserAPIManager.shared.getUserInfo()
            
            // 사용자 정보 조회 성공 시 메인 화면 이동
            DispatchQueue.main.async {
                self.flow = .main
            }
        } catch {
            // 재발급 실패 또는 사용자 정보 조회 실패 시 로그인 화면 이동
            DispatchQueue.main.async {
                self.flow = .login
            }
        }
    }
}
