//
//  LoginView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    
    @State var email: String = ""
    @State var password: String = ""
//    var isFilled: Bool {
//        !email.isEmpty && !password.isEmpty
//    }
    
    var isFilled = true

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @ObservedObject var viewModel: LoginViewModel = .init()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background1Ws
                    .ignoresSafeArea()
                
                VStack {
                    Image("logo")
                        .padding(.bottom, 80)
                    
                    TextField("이메일을 입력하세요", text: $email)
                        .textInputAutocapitalization(.never) // 자동 대문자처리 해제
                        .keyboardType(.emailAddress)
                        .foregroundStyle(Color.gray)
                        .font(.bmjua(.regular, size: 22))
                        .frame(height: 60)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.bottom, 12)
                    
                    SecureField("비밀번호를 입력하세요", text: $password)
                        .foregroundStyle(Color.gray)
                        .font(.bmjua(.regular, size: 22))
                        .frame(height: 60)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.bottom, 20)
                    
                    Button {
                        if email.isEmpty || password.isEmpty {
                            alertMessage = "이메일과 비밀번호를 모두 입력해주세요."
                            showAlert = true
                        } else if !isValidEmail(email) {
                            alertMessage = "이메일 형식이 올바르지 않습니다."
                            showAlert = true
                        } else {
                            viewModel.email = email
                            viewModel.password = password
                            
                            Task {
                                let isLoggedIn = await viewModel.login()
                                
                                if isLoggedIn {
                                    await viewModel.attendanceCheck()
                                    appState.flow = .main
                                } else {
                                    // 401 -> 이메일이나 비번이 바르지 않을 경우
                                    // 400 -> 이메일 제대로, 비밀번호 틀렸을 경우
                                    // APIErrorResponse(message: Optional(["비밀번호는 영문, 숫자, 특수문자 중 2가지 이상 조합으로 8~16자여야 합니다."]), error: "Bad Request", statusCode: 400)
                                    // 그 외 이메일 형식 검사 및 빈 필드는 프론트에서 처리
                                    showAlert = true
                                    alertMessage = viewModel.errorMessage ?? "알 수 없는 에러가 발생했습니다."
                                }
                            }
                        }
                        
                        print("loginView: \(viewModel.email)")
                        print("loginView: \(viewModel.password)")
                        
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFilled ? Color.mainws: Color.gray)
                                .frame(height: 60)
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                            
                            Text("로그인")
                                .font(.bmjua(.regular, size: 24))
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                    }
                    .alert(alertMessage, isPresented: $showAlert) {
                        Button("확인", role: .cancel) { }
                    }
                    .disabled(!isFilled)
                    .padding(.bottom, 40)
                    
                    
                    HStack {
                        Button {
                            appState.flow = .signUp
                        } label: {
                            Text("회원가입")
                                .foregroundStyle(Color.gray)
                                .font(.bmjua(.regular, size: 20))
                        }
                        
                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: ResetPasswordView(isLoginView: true)) {
                            Text("비밀번호 재설정")
                                .foregroundStyle(Color.gray)
                                .font(.bmjua(.regular, size: 20))
                        }
                    }
                    .padding(.bottom, 68)
                    
                    HStack {
                        Button {
                            // 카카오 로그인
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.kakao)
                                    .frame(width: 50, height: 50)
                                
                                Image("kakao")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            }
                        }
                        .padding(.trailing, 16)
                        
                        Button {
                            // 구글 로그인
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.google)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle().stroke(Color.gray, lineWidth: 1)
                                    )
                                
                                Image("google")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            }
                        }
                        .padding(.trailing, 16)
                        
                        Button {
                            // 애플 로그인
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.apple)
                                    .frame(width: 50, height: 50)
                                
                                Image("apple")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            }
                        }
                    }
                }
                .padding()
            }
            .hideKeyboardOnTap()
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx =
        #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
}

#Preview {
    LoginView()
}
