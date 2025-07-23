//
//  UserAPITestView.swift
//  worlds-fe-v20
//
//  Created by soy on 7/21/25.
//

import SwiftUI

struct UserAPITestView: View {
    @State var email: String = ""
    @State var errorMessage: String?
    
    @State var old: String = ""
    @State var new: String = ""
    
    @State var userName: String = ""
    
    var body: some View {
        VStack {
            
            TextField("이메일을 입력하세요", text: $email)
                .keyboardType(.emailAddress)
                .foregroundStyle(Color.gray)
                .font(.system(size: 20))
                .frame(height: 60)
                .padding(.horizontal, 14)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.bottom, 12)
            
            Button {
                Task {
                   await checkEmail()
                }
            } label: {
                Text("이메일 인증")
            }
            
            Button {
                Task {
                   await newToken()
                }
            } label: {
                Text("토큰 발급")
            }
            
            Button {
                Task {
                   await gerUserInfo()
                }
            } label: {
                Text("사용자 정보")
            }
            
            TextField("이전 비밀 번호", text: $old)
                .foregroundStyle(Color.gray)
                .font(.system(size: 20))
                .frame(height: 60)
                .padding(.horizontal, 14)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.bottom, 12)
            
            TextField("새로운 비밀 번호", text: $new)
                .keyboardType(.emailAddress)
                .foregroundStyle(Color.gray)
                .font(.system(size: 20))
                .frame(height: 60)
                .padding(.horizontal, 14)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.bottom, 12)
            
            Button {
                Task {
                   await changePassword()
                }
            } label: {
                Text("비번 변경")
            }
            
            TextField("이메일 찾기", text: $userName)
                .keyboardType(.emailAddress)
                .foregroundStyle(Color.gray)
                .font(.system(size: 20))
                .frame(height: 60)
                .padding(.horizontal, 14)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.bottom, 12)
            
            Button {
                Task {
                    await findEmail()
                }
            } label: {
                Text("이멜찾기")
            }
            
            Button {
                Task {
                    await logout()
                }
            } label: {
                Text("로그아웃")
            }

        }
        .padding()
        .background(Color.gray)
    }
    
    // 이메일 인증
    func checkEmail() async {
        do {
            let user = try await UserAPIManager.shared.emailCheck(email: email)
            print("이메일 인증: \(user)")
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
    
    func newToken() async {
        do {
            let user = try await UserAPIManager.shared.getNewAccessToken()
            print("토큰 재발급: \(user)")
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
    
    func gerUserInfo() async {
        do {
            let user = try await UserAPIManager.shared.getUserInfo()
            print("사용자 정보: \(user)")
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
    
    func logout() async {
        do {
            let user = try await UserAPIManager.shared.logout()
            print("로그아웃: \(user)")
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
    
    func changePassword() async {
        do {
            let user = try await UserAPIManager.shared.changePassword(oldPassword: old, newPassword: new)
            print("비번변경: \(user)")
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
    
    func findEmail() async {
        do {
            let user = try await UserAPIManager.shared.findEmail(name: userName)
            print("userName: \(userName)")
            print("이멜찾기: \(user)")
        } catch {
            errorMessage = error.localizedDescription
            print(errorMessage)
        }
    }
}

#Preview {
    UserAPITestView()
}
