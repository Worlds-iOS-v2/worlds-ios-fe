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
    @Environment(\.dismiss) var dismiss

    @State var email: String = ""
    @State var password: String = ""
    @State var passwordCheck: String = ""
    
//    var isFilled: Bool {
//        !email.isEmpty &&
//        isValidEmail(email) &&
//        !password.isEmpty &&
//        !passwordCheck.isEmpty &&
//        password == passwordCheck
//    }
    var isFilled = true
    @State var isSuceed: Bool = false
    
    @EnvironmentObject var viewModel: SignUpViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("로그인 정보를 입력해주세요.")
                    .font(.system(size: 27, weight: .bold))
                    .padding(.top, 40)
                
                CommonSignUpTextField(title: "이메일", placeholder: "이메일을 입력해주세요", content: $email)
                    .keyboardType(.emailAddress)
                    .padding(.bottom, 40)
                    .padding(.top, 40)
                
                //            if !email.isEmpty && !isValidEmail(email) {
                //                Text("올바른 이메일 형식이 아닙니다.")
                //                    .foregroundColor(.red)
                //                    .font(.caption)
                //            }
                
                CommonSignUpTextField(title: "비밀번호", placeholder: "비밀번호를 입력해주세요", isSecure: true, content: $password)
                    .padding(.bottom, 40)
                
                CommonSignUpTextField(title: "비밀번호 확인", placeholder: "비밀번호를 한 번 더 입력해주세요.", isSecure: true, content: $passwordCheck)
                    .padding(.bottom, 40)
                
                Spacer()
                
                CommonSignUpButton(text: "다음", isFilled: isFilled) {
                    // viewmodel에 데이터 전송                    
                    viewModel.email = email
                    viewModel.password = password
                    
                    print("signup Account View: \(viewModel.email)")
                    print("signup Account View: \(viewModel.password)")
                    
                    // viewModel 호출 후 화면 전환 (어떤 방식이 더 효율적인지는 아직 모르겠음)
                    isSuceed = true
                }
                .padding(.bottom, 12)
            }
            
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .navigationDestination(isPresented: $isSuceed) {
            SignUpDetailProfileView()
        }
        .hideKeyboardOnTap()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx =
        #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
}

#Preview {
    SignUpAccountView()
        .environmentObject(SignUpViewModel())
}
