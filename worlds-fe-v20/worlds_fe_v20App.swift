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
              
                // 런치 스크린
            case .launch:
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    ProgressView("자동 로그인 중…")
                }
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
                
                // 추후 메인 화면으로 변경
            case .main:
                RootRouter()
                    .environmentObject(appState)
            }
        }
    }
}

struct RootRouter: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var myPageVM = MyPageViewModel()
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    ProgressView("불러오는 중…")
                }
            } else {
                if let user = myPageVM.userInfo,
                   !(user.profileImage?.isEmpty ?? true) || !(user.profileImageUrl?.isEmpty ?? true) {
                    TabbarView()
                        .environmentObject(appState)
                } else {
                    PuzzleCharactersMainView()
                        .environmentObject(myPageVM)
                        // Force a lightweight refresh when profile changes so navigation updates immediately
                        .id((myPageVM.userInfo?.profileImage ?? "") + (myPageVM.userInfo?.profileImageUrl ?? ""))
                }
            }
        }
        .task {
            await myPageVM.fetchMyInformation()
            isLoading = false
        }
    }
}
