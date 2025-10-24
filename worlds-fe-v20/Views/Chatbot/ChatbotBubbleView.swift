//
//  ChatbotBubbleView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

import SwiftUI

struct ChatbotBubble: View {
    let message: ChatbotMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.pretendard(.regular, size: 16))
                        .padding(12)
                        .foregroundColor(.white)
                        .background(.mainws)
                        .cornerRadius(16)
                    
                    Text(timeString(from: message.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(message.content)
                            .font(.pretendard(.regular, size: 16))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.mainws, lineWidth: 1)
                            )
                        
                        Text(timeString(from: message.timestamp))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {
                        // 번역 기능
                    }) {
                        Text("번역하기")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

