//
//  worlds_fe_v20App.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/4/25.
//

import SwiftUI

@main
struct worlds_fe_v20App: App {
    @StateObject private var appState = AppState()
    @StateObject private var signUpViewModel = SignUpViewModel()

    var body: some Scene {
        WindowGroup {
            switch appState.flow {
                
            // 로그인 화면
            case .login:
                LoginView()
                    .environmentObject(appState)
            
            // 회원가입 화면
            case .signUp:
                SignUpRoleSelectionView()
                    .environmentObject(appState)
                    .environmentObject(signUpViewModel)
            
            // 추후 메인 화면으로 변경
            case .main:
                ContentView()
                    .environmentObject(appState)
            }
        }
    }
}
