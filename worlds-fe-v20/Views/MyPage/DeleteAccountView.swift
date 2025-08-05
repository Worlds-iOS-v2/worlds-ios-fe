//
//  DeleteAccountView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/1/25.
//

import SwiftUI

struct DeleteAccountView: View {
    @StateObject var viewModel: MyPageViewModel = MyPageViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("탈퇴 하시겠습니까?")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Text("탈퇴할 경우, 모든 데이터는 삭제되며 다시 복구되지 않습니다.")
                .font(.system(size: 20))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.deleteAccount()
                    appState.flow = .login
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red)
                        .frame(height: 60)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                    
                    HStack {
                        Text("회원탈퇴")
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .navigationTitle("회원탈퇴")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.mainws)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
    }
}
