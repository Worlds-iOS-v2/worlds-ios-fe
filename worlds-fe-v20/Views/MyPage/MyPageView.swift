//
//  MyPageView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/31/25.
//

import SwiftUI

struct MyPageView: View {
    @Environment(\.openURL) var openURL
    @StateObject var viewModel: MyPageViewModel = MyPageViewModel()
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.sub2Ws
                .ignoresSafeArea()
            
            VStack {
                VStack {
                    Text("마이페이지")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    UserInfoCardView(userInfo: viewModel.userInfo)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 40)
                
                VStack(spacing: 16) {
                    NavigationLink(destination: MyQuestionView(questions: viewModel.questions)) {
                        Text("내가 쓴 글")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 32)
                    .onAppear{
                        Task {
                            await viewModel.fetchMyQuestions()
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    Button {
                        alertMessage = "로그아웃 하시겠습니까?"
                        showAlert = true
                    } label: {
                        Text("로그아웃")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 32)
                    .alert(alertMessage, isPresented: $showAlert) {
                        Button("확인", role: .cancel) {
                            Task {
                                await viewModel.logout()
                                appState.flow = .login
                            }
                        }
                        Button("취소", role: .destructive) { }
                    }
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    Link("이용약관", destination: URL(string: "https://www.notion.so/World-Study-_2-0-0-1fc800c9877b80d6a86ce296013ec7d7?source=copy_link")!)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    HStack {
                        Text("버전 정보")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        Text("\(appVersion())")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 32)
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    NavigationLink(destination: DeleteAccountView()) {
                        Text("회원탈퇴")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.backgroundws)
                        .padding(.horizontal, 16)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                )
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            // 정보 불러오기
            Task {
                await viewModel.fetchMyInformation()
            }
        }
    }
}

extension MyPageView {
    private func appVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "알 수 없음"
        }
        
        return version
    }
}

//#Preview {
//    MyPageView()
//}
