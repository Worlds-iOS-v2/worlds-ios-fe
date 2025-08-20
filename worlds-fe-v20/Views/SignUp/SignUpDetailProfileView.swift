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
    
    @State var birthDate = Date()
    @State var birthYear: Int = Calendar.current.component(.year, from: Date())
    @State var birthMonth: Int = Calendar.current.component(.month, from: Date())
    @State var birthDay: Int = Calendar.current.component(.day, from: Date())
    
    @State var isDatePickerPresented: Bool = false
    
    var isFilled: Bool {
        !name.isEmpty
    }
    
    var textColor: Color = .mainfontws
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @EnvironmentObject var viewModel: SignUpViewModel
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("사용자 정보를 입력해주세요.")
                    .font(.bmjua(.regular, size: 27))
                    .foregroundColor(textColor)
                    .padding(.top, 40)
                
                CommonSignUpTextField(title: "이름", placeholder: "이름을 입력해주세요", content: $name)
                    .padding(.bottom, 40)
                    .padding(.top, 40)
                
                // 전화번호 입력 부분 주석처리.
                //                CommonSignUpTextField(title: "전화번호", placeholder: "전화번호를 입력해주세요", content: $phoneNumber)
                //                    .keyboardType(.numberPad)
                //                    .padding(.bottom, 40)
                
                Text("생년월일")
                    .foregroundStyle(textColor)
                    .font(.bmjua(.regular, size: 22))
                    .fontWeight(.semibold)
                
                Button {
                    isDatePickerPresented.toggle()
                } label: {
                    HStack {
                        Text("\(String(birthYear))년 \(birthMonth)월 \(birthDay)일")
                            .foregroundStyle(Color.gray)
                            .font(.bmjua(.regular, size: 22))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)
                        
                        Spacer()
                        
                        Image(systemName: "calendar")
                            .foregroundColor(Color.mainws)
                            .padding(.horizontal, 16)
                    }
                    .background{
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(Color.white)
                            .frame(height: 60)
                    }
                }
                .padding(.vertical, 16)
                
                if isDatePickerPresented {
                    // 커스텀 데이터피커 오류 발생 이슈로 주석처리..
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
                            ForEach(1...daysInMonth(year: birthYear, month: birthMonth), id: \.self) { day in
                                Text("\(day)일").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .font(.bmjua(.regular, size: 20))
                    .foregroundStyle(textColor)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
            }
            
            Spacer()
            
            CommonSignUpButton(text: "완료", isFilled: isFilled) {
                viewModel.name = name
                
                let calendar = Calendar.current
                var dateComponents = DateComponents()
                dateComponents.year = birthYear
                dateComponents.month = birthMonth
                dateComponents.day = birthDay
                viewModel.birthDate = calendar.date(from: dateComponents)?.toStringForServer() ?? Date().toStringForServer()
                
                Task {
                    let isSignIn = await viewModel.signup()
                    
                    if isSignIn {
                        // 확인 버튼 액션
                        appState.flow = .login
                    } else {
                        showAlert = true
                        alertMessage = viewModel.errorMessage ?? "알 수 없는 에러 발생"
                    }
                }
            }
            .padding(.bottom, 12)
            
            Button {
                appState.flow = .login
            } label: {
                Text("로그인 하기")
                    .foregroundStyle(Color.gray)
                    .font(.bmjua(.regular, size: 16))
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        }
        .padding()
        .background(.background1Ws)
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
        .hideKeyboardOnTap()
    }
    
    func daysInMonth(year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let cal = Calendar.current
        // 해당 월 1일로 날짜 생성
        let date = cal.date(from: comps)!
        // 그 달의 일 개수 얻기
        return cal.range(of: .day, in: .month, for: date)!.count
    }
}

#Preview {
    SignUpDetailProfileView()
        .environmentObject(SignUpViewModel())
}
