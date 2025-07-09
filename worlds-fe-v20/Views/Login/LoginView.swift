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

    var body: some View {
        ZStack {
            Color.backgroundws
                .ignoresSafeArea()
            
            VStack {
                Image("logo")
                    .resizable()
                    .frame(width: 295)
                    .scaledToFit()
                    .padding(.bottom, 80)
                
                TextField("이메일을 입력하세요", text: $email)
                    .keyboardType(.emailAddress)
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 20))
                    .frame(height: 50)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.bottom, 24)
                
                SecureField("비밀번호를 입력하세요", text: $password)
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 20))
                    .frame(height: 50)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.bottom, 32)
                
                Button {
//                    if email.isEmpty || password.isEmpty {
//                        alertMessage = "이메일과 비밀번호를 모두 입력해주세요."
//                        showAlert = true
//                    } else if !isValidEmail(email) {
//                        alertMessage = "이메일 형식이 올바르지 않습니다."
//                        showAlert = true
//                    } else {
//                        // 로그인 진행
//                        appState.flow = .main
//                    }
                    appState.flow = .main
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(isFilled ? Color.brownws: Color.gray)
                            .frame(height: 50)
                        
                        Text("로그인")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
                .alert("오류", isPresented: $showAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
                .disabled(!isFilled)
                .padding(.bottom, 40)
                
                
                HStack {
                    Button {
                        appState.flow = .signUp
                    } label: {
                        Text("회원가입")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 20))
                    }
                    
                    Divider()
                        .frame(height: 20)
                        .padding(.horizontal)
                    
                    Button {
                        // 비밀번호 수정
                    } label: {
                        Text("비밀번호 재설정")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 20))
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
