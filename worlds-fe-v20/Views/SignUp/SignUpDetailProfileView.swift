//
//  SignUpMenteeProfileView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct SignUpDetailProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State var name: String = ""
    @State var phoneNumber: String = ""

    @State var birthYear: Int = Calendar.current.component(.year, from: Date())
    @State var birthMonth: Int = Calendar.current.component(.month, from: Date())
    @State var birthDay: Int = Calendar.current.component(.day, from: Date())
    
    @State var isDatePickerPresented: Bool = false
    @State var isFilled: Bool = true
    
    @EnvironmentObject var viewModel: SignUpViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("사용자 정보를 입력해주세요.")
                    .font(.system(size: 27, weight: .bold))
                    .padding(.top, 40)
                
                CommonSignUpTextField(title: "이름", placeholder: "이름을 입력해주세요", content: $name)
                    .padding(.bottom, 40)
                    .padding(.top, 40)
                
                CommonSignUpTextField(title: "전화번호", placeholder: "전화번호를 입력해주세요", content: $phoneNumber)
                    .keyboardType(.numberPad)
                    .padding(.bottom, 40)
                
                Text("생년월일")
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                
                Button {
                    isDatePickerPresented.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color.white)
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                            .frame(height: 60)
                        
                        Text("\(String(birthYear))년 \(birthMonth)월 \(birthDay)일")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)
                    }
                }
                    
                if isDatePickerPresented {
                    HStack(spacing: 0) {
                        // 년
                        Picker("년도", selection: $birthYear) {
                            ForEach(1900...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                Text("\(String(year))년").tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        
                        // 월
                        Picker("월", selection: $birthMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text("\(month)월").tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        
                        // 일
                        Picker("일", selection: $birthDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)일").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
            }
            
            Spacer()
            
            CommonSignUpButton(text: "완료", isFilled: isFilled) {
                // viewmodel에 데이터 전송
                print("nextPage")
                
                appState.flow = .login
            }
            .padding(.bottom, 12)
            
            Button {
                appState.flow = .login
            } label: {
                Text("로그인 하기")
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 14))
            }
        }
        .padding()
        .background(.backgroundws)
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    SignUpDetailProfileView()
        .environmentObject(SignUpViewModel())
}
