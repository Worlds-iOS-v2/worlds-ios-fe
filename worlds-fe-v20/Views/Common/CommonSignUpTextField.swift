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

    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title)")
                .foregroundStyle(Color.gray)
                .font(.system(size: 20))
                .fontWeight(.semibold)
            
            if isSecure {
                SecureField("\(placeholder)", text: $content)
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 20))
                    .frame(height: 50)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(10)
                
            } else {
                TextField("\(placeholder)", text: $content)
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 20))
                    .frame(height: 50)
                    .padding(.horizontal, 14)
                    .background(Color.white)
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    // CommonSignUpTextField(title: "이메일", placeholder: "이메일을 입력해주세요.")
}
