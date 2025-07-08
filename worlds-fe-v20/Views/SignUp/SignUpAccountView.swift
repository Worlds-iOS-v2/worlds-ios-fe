//
//  SignUpView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

/// 회원가입 2번째 화면 - 이메일, 비밀번호 입력
struct SignUpAccountView: View {
    @EnvironmentObject var appState: AppState

    @State var email: String = ""
    @State var password: String = ""
    @State var passwordCheck: String = ""
    
    @State var isFilled: Bool = true
    @State var isSuceed: Bool = false
    
    @EnvironmentObject var viewModel: SignUpViewModel
    
    var body: some View {
        VStack {
            CommonSignUpTextField(title: "이메일", placeholder: "이메일을 입력해주세요", content: $email)
                .keyboardType(.emailAddress)
                .padding(.bottom, 40)
                .padding(.top, 80)
            
            CommonSignUpTextField(title: "비밀번호", placeholder: "비밀번호를 입력해주세요", isSecure: true, content: $password)
                .padding(.bottom, 40)
                        
            CommonSignUpTextField(title: "비밀번호 확인", placeholder: "비밀번호를 한 번 더 입력해주세요.", isSecure: true, content: $passwordCheck)
                .padding(.bottom, 40)
            
            Spacer()
            
            CommonSignUpButton(text: "다음", isFilled: $isFilled) {
                // viewmodel에 데이터 전송
                print("SignUpDetailProfileView")
                
                viewModel.email = email
                viewModel.password = password
                
                // viewModel 호출 후 화면 전환 (어떤 방식이 더 효율적인지는 아직 모르겠음)
                isSuceed = true
            }
            .padding(.bottom, 12)
            
            Button {
                appState.flow = .login
            } label: {
                Text("로그인 하기")
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 14))
            }
        }
        .padding()
        .background(.backgroundws)
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isSuceed) {
            SignUpDetailProfileView()
        }
    }
}

#Preview {
    SignUpAccountView()
        .environmentObject(SignUpViewModel())
}
