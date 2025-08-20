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

    /// 앱 시작 시 자동 로그인/진입 분기
    /// - accessToken은 매번 재발급(갱신)하고, 사용자 정보 조회까지 성공하면 .main
    /// - 실패 시 토큰 정리 후 .login
    @MainActor
    func autoLogin() async {
        // 1) 저장된 refreshToken 없으면 로그인 화면
        guard let _ = UserDefaults.standard.string(forKey: "refreshToken") else {
            self.flow = .login
            return
        }

        do {
            // 2) 액세스 토큰 재발급 → 사용자 정보 조회
            _ = try await UserAPIManager.shared.getNewAccessToken()
            _ = try await UserAPIManager.shared.getUserInfo()

            // 3) 성공 시 메인으로
            self.flow = .main
        } catch {
            // 4) 실패 시 보관 토큰 정리 후 로그인으로
            UserDefaults.standard.removeObject(forKey: "accessToken")
            UserDefaults.standard.removeObject(forKey: "refreshToken")
            self.flow = .login
        }
    }
}
