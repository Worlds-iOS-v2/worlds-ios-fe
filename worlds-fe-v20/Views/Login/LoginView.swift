//
//  LoginView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = SignUpViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink(destination: SignUpRoleSelectionView()) {
                    Text("회원가입")
                }
                .padding(.top, 40)
            }
            .padding()
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    LoginView()
}
