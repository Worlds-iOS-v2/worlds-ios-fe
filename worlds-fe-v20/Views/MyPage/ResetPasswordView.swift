//
//  ResetPasswordView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/5/25.
//

import SwiftUI

struct ResetPasswordView: View {
    @StateObject var viewModel: MyPageViewModel = MyPageViewModel()
    @Environment(\.dismiss) var dismiss

    @State var oldPassword: String = ""
    @State var newPassword: String = ""
    @State var passwordCheck: String = ""
    
    var isFilled: Bool {
        !oldPassword.isEmpty &&
        isValidPassword(oldPassword) &&
        !newPassword.isEmpty &&
        !passwordCheck.isEmpty &&
        newPassword == passwordCheck
    }
    @State var isSuceed: Bool = false
        
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("변경할 비밀번호를 입력해주세요.")
                    .font(.system(size: 27, weight: .bold))
                    .padding(.top, 40)
                
                CommonSignUpTextField(title: "기존 비밀번호", placeholder: "기존 비밀번호를 입력해주세요", isSecure: true, content: $oldPassword)
                    .padding(.top, 40)
                
                if !oldPassword.isEmpty && !isValidPassword(oldPassword) {
                    Text("비밀번호는 영문, 숫자, 특수문자 중 2가지 이상 조합으로 8~16자여야 합니다.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                CommonSignUpTextField(title: "비밀번호", placeholder: "비밀번호를 입력해주세요", isSecure: true, content: $newPassword)
                    .padding(.top, 40)
                
                if !newPassword.isEmpty && !isValidPassword(newPassword) {
                    Text("비밀번호는 영문, 숫자, 특수문자 중 2가지 이상 조합으로 8~16자여야 합니다.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                CommonSignUpTextField(title: "비밀번호 확인", placeholder: "비밀번호를 한 번 더 입력해주세요.", isSecure: true, content: $passwordCheck)
                    .padding(.top, 40)
                
                if !passwordCheck.isEmpty && newPassword != passwordCheck {
                    Text("비밀번호가 일치하지 않습니다.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                CommonSignUpButton(text: "완료", isFilled: isFilled) {
                    Task {
                        await viewModel.resetPassword(oldPassword: oldPassword, newPassword: newPassword)
                        
                        dismiss()
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 12)
            }
        }
        .padding()
        .background(.backgroundws)
        .navigationTitle("비밀번호 변경")
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
}

extension ResetPasswordView {
    func isValidPassword(_ password: String) -> Bool {
        // 길이 검사 (8자 이상 ~ 16자 이하)
        guard password.count >= 8 && password.count <= 16 else {
            return false
        }
        
        // 포함 조건 개수 세기
        var conditionsMet = 0
        
        // 영문 포함 여부 (대소문자 구분 없음)
        let letterRegex = ".*[A-Za-z]+.*"
        if NSPredicate(format: "SELF MATCHES %@", letterRegex).evaluate(with: password) {
            conditionsMet += 1
        }
        
        // 숫자 포함 여부
        let numberRegex = ".*[0-9]+.*"
        if NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: password) {
            conditionsMet += 1
        }
        
        // 특수문자 포함 여부 (영문,숫자 제외 모든 문자 포함)
        let specialCharRegex = ".*[^A-Za-z0-9]+.*"
        if NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) {
            conditionsMet += 1
        }
        
        // 최소 2가지 조건 이상 만족해야 함
        return conditionsMet >= 2
    }
}
//
//#Preview {
//    SignUpAccountView()
//        .environmentObject(SignUpViewModel())
//}
