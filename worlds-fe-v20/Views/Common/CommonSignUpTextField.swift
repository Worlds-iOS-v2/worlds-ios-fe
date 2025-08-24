//
//  CommonSignUpTextField.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct CommonSignUpTextField: View {
    var title: String = ""
    var placeholder: String = ""
    var isSecure: Bool = false
    var textColor: Color = .mainfontws

    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title)")
                .foregroundStyle(textColor)
                .font(.pretendard(.semiBold, size: 22))
            
            if isSecure {
                SecureField("\(placeholder)", text: $content)
                    .foregroundStyle(textColor)
                    .font(.pretendard(.medium, size: 22))
                    .frame(height: 60)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(12)

            } else {
                TextField("\(placeholder)", text: $content)
                    .textInputAutocapitalization(.never) // 자동 대문자처리 해제
                    .foregroundStyle(textColor)
                    .font(.pretendard(.medium, size: 22))
                    .frame(height: 60)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    // CommonSignUpTextField(title: "이메일", placeholder: "이메일을 입력해주세요.")
}
