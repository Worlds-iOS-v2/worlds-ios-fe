//
//  worlds_fe_v20App.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/4/25.
//

import SwiftUI
import KakaoSDKCommon

@main
struct worlds_fe_v20App: App {
    @StateObject private var appState = AppState()
    @StateObject private var signUpViewModel = SignUpViewModel()
    
    init() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "KakaoNativeAppKey") as? String else {
            print("appKey가 존재하지 않습니다.")
            return
        }
        print("Info.plist에서 읽은 카카오 앱 키: \(Bundle.main.object(forInfoDictionaryKey: "KakaoNativeAppKey") ?? "없음")")
        
        KakaoSDK.initSDK(appKey: appKey)
    }
    
    var body: some Scene {
        WindowGroup {
            switch appState.flow {
                
                // 런치 스크린
            case .launch:
                LaunchView()
                    .task {
                        await appState.autoLogin()
                    }
                
                // 로그인 화면
            case .login:
                LoginView()
                    .environmentObject(appState)
                
                // 회원가입 화면
            case .signUp:
                SignUpRoleSelectionView()
                    .environmentObject(appState)
                    .environmentObject(signUpViewModel)
                
                // 프로필 이미지 선택 화면
            case .profileSelection:
                ProfileImageSelectionView()
                    .environmentObject(appState)
                
                // 메인 화면
            case .main:
                CustomTabBarView()
                    .environmentObject(appState)
            }
        }
    }
}
