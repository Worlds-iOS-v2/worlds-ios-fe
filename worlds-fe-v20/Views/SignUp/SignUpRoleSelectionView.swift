//
//  SignUpRoleSelectionView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

/// 회원가입 1번째 페이지 - 멘토/멘티 선택 화면
struct SignUpRoleSelectionView: View {
    @EnvironmentObject var appState: AppState
    
    @State var selectedRole: UserRole = .none
    @State var isSelected: Bool = false
    @State var isSuceed: Bool = false
    
    @EnvironmentObject var viewModel: SignUpViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("누가 사용할 계정인가요?")
                    .font(.system(size: 27, weight: .bold))
                    .padding(.top, 40)
                
                HStack(alignment: .center) {
                    
                    Spacer()
                    
                    Button {
                        print("mentor")
                        selectedRole = .mentor
                        isSelected = true
                        
                        viewModel.isMentor = true
                    } label: {
                        VStack {
                            Image("mentor")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding()
                            
                            Spacer()
                            
                            Text("멘토")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.black)
                        }
                        .padding()
                        .background(selectedRole == .mentor ? Color.sub2Ws : Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.sub1Ws, lineWidth: 2)
                                .opacity(selectedRole == .mentor ? 1 : 0)
                        )
                        .frame(width: 155, height: 166)
                    }
                    
                    Button {
                        print("mentee")
                        selectedRole = .mentee
                        isSelected = true
                        
                        viewModel.isMentor = false
                    } label: {
                        VStack {
                            Image("mentee")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            
                            Spacer()
                            
                            Text("멘티")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.black)
                        }
                        .padding()
                        .background(selectedRole == .mentee ? Color.sub2Ws : Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.sub1Ws, lineWidth: 2)
                                .opacity(selectedRole == .mentee ? 1 : 0)
                        )
                        .frame(width: 155, height: 166)
                    }
                    
                    Spacer()
                }
                .padding(.top, 24)
                
                Spacer()
                
                CommonSignUpButton(text: "다음", isFilled: isSelected) {
                    // viewmodel에 데이터 전송
                    print("SignUpAccountView")
                    
                    print("SignUpAccountView: \(viewModel.isMentor)")
                    
                    // viewModel 호출 후 화면 전환 (어떤 방식이 더 효율적인지는 아직 모르겠음)
                    isSuceed = true
                }
                .padding(.bottom, 12)
                
                Button {
                    appState.flow = .login
                } label: {
                    Text("로그인 하기")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 14))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .padding()
            .background(.backgroundws)
            .navigationTitle("회원가입")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        appState.flow = .login
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .navigationDestination(isPresented: $isSuceed) {
                SignUpAccountView()
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    SignUpRoleSelectionView()
        .environmentObject(SignUpViewModel())
}
