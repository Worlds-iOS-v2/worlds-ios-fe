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
                    .fill(Color.sub1Ws)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                    
                    if let userImage = userInfo?.profileImage {
                        Image("\(userImage)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                    } else {
                        Image("mentee")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                }
                .padding(.top, 50)
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("이름")
                        .font(.pretendard(.semiBold, size: textSize))

                    Spacer()
                    
                    if let userInfo = userInfo {
                        Text("\(userInfo.userName)")
                            .font(.pretendard(.regular, size: textSize))
                    } else {
                        Text("알 수 없음")
                            .font(.pretendard(.regular, size: textSize))
                    }
                }
                .foregroundStyle(textColor)
                .padding(.bottom, 8)
                
                HStack {
                    Text("이메일")
                        .font(.pretendard(.semiBold, size: textSize))
                    
                    Spacer()
                    
                    if let userInfo = userInfo {
                        Text("\(userInfo.userEmail)")
                            .font(.pretendard(.regular, size: textSize))

                    } else {
                        Text("알 수 없음")
                            .font(.pretendard(.regular, size: textSize))
                    }
                }
                .foregroundStyle(textColor)
                .padding(.bottom, 8)
                
                HStack {
                    Text("비밀번호")
                        .font(.pretendard(.semiBold, size: textSize))
                        .foregroundStyle(textColor)

                    Spacer()
                    
                    NavigationLink(destination: ResetPasswordView()) {
                        Text("비밀번호 재설정")
                            .font(.pretendard(.regular, size: textSize))
                    }
                }
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
