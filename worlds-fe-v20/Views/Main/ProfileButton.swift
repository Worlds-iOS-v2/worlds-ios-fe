//
//  ProfileButton.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/15/25.
//

import SwiftUI

struct ProfileButton: View {
    var body: some View {
        NavigationLink(destination: MyPageView()) {
            ZStack {
                Circle()
                    .stroke(.mainws, lineWidth: 0.5)
                    .background(Circle().fill(Color.white))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
