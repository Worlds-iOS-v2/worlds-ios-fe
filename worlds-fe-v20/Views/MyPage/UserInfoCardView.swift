//
//  UserInfoCardView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/1/25.
//

import SwiftUI

struct UserInfoCardView: View {
    var userInfo: User?
    
    var textSize: CGFloat = 16
    var textColor: Color = .mainfontws

    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.mainws)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                    
                    Image("mentee")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
                .padding(.top, 50)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("이름")

                    Spacer()
                    
                    if let userInfo = userInfo {
                        Text("\(userInfo.userName)")
                    } else {
                        Text("알 수 없음")
                    }
                }
                .font(.bmjua(.regular, size: textSize))
                .foregroundStyle(textColor)
                .padding(.bottom, 8)
                
                HStack {
                    Text("이메일")
                    
                    Spacer()
                    
                    if let userInfo = userInfo {
                        Text("\(userInfo.userEmail)")

                    } else {
                        Text("알 수 없음")
                    }
                }
                .font(.bmjua(.regular, size: textSize))
                .foregroundStyle(textColor)
                .padding(.bottom, 8)
                
                HStack {
                    Text("비밀번호")
                        .foregroundStyle(textColor)

                    Spacer()
                    
                    NavigationLink(destination: ResetPasswordView()) {
                        Text("비밀번호 재설정")
                    }
                }
                .font(.bmjua(.regular, size: textSize))
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.background1Ws)
    }
}

//#Preview {
//    UserInfoCardView()
//}
