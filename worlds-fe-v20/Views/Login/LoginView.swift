//
//  LoginView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct LoginView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var isFilled: Bool = false
    
    @StateObject private var viewModel = SignUpViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundws
                    .ignoresSafeArea()
                
                VStack {
                    Image("logo")
                        .resizable()
                        .frame(width: 295)
                        .scaledToFit()
                        .padding(.bottom, 80)
                    
                    TextField("이메일을 입력하세요", text: $email)
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .frame(height: 50)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .cornerRadius(25)
                        .padding(.bottom, 24)
                    
                    TextField("비밀번호를 입력하세요", text: $password)
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .frame(height: 50)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .cornerRadius(25)
                        .padding(.bottom, 32)
                    
                    Button {
                        // 로그인 진행
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(isFilled ? Color.brownws: Color.gray)
                                .frame(height: 50)
                            
                            Text("로그인")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFilled)
                    .padding(.bottom, 40)
                    
                    
                    HStack {
                        NavigationLink(destination: SignUpRoleSelectionView()) {
                            Text("회원가입")
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 20))
                        }
                        
                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal)
                        
                        Button {
                            // 비밀번호 수정
                        } label: {
                            Text("비밀번호 재설정")
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.bottom, 68)
                    
                    HStack {
                        Button {
                            // 카카오 로그인
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.kakao)
                                    .frame(width: 50, height: 50)
                                
                                Image("kakao")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            }
                        }
                        .padding(.trailing, 16)
                        
                        Button {
                            // 구글 로그인
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.google)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle().stroke(Color.gray, lineWidth: 1)
                                    )
                                
                                Image("google")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            }
                        }
                        .padding(.trailing, 16)
                        
                        Button {
                            // 애플 로그인
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.apple)
                                    .frame(width: 50, height: 50)
                                
                                Image("apple")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    LoginView()
}
