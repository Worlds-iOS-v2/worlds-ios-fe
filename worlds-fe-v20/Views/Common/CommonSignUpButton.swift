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
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFilled ? Color.brownws: Color.gray)
                    .frame(height: 60)
                
                Text("\(text)")
                    .font(.system(size: 24))
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
