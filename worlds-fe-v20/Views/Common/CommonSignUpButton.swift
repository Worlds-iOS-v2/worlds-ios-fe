//
//  CommonSignUpButton.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct CommonSignUpButton: View {
    var text: String
    var isFilled: Bool
    var action: () -> Void
    
    var body: some View {
        Button (action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFilled ? Color.mainws: Color.gray)
                    .frame(height: 60)
                    // .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                
                Text("\(text)")
                    .font(.pretendard(.bold, size: 24))
                    .foregroundStyle(.white)
            }
        }
        .disabled(!isFilled)
    }
}

#Preview {
//    CommonSignUpButton(text: "다음") {
//        
//    }
}
