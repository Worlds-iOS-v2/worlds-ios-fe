//
//  SignUpMenteeProfileView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

struct SignUpDetailProfileView: View {
    @State var name: String = ""
    @State var phoneNumber: String = ""
    @State var birthDate = Date()
    @State var isDatePickerPresented: Bool = false
    @State var isFilled: Bool = true
    @State var isSuceed: Bool = false
    
    @State private var selectedGrade = "학년 선택"
    let options = ["1학년", "2학년", "3학년", "4학년", "5학년", "6학년"]

    let subjectRows = [
        ["국어", "영어", "수학", "과학"],
        ["사회", "역사", "예체능"]
    ]
    @State var selectedSubjects: [String: Bool] = [:]
    
    @EnvironmentObject var viewModel: SignUpViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                
                CommonSignUpTextField(title: "이름", placeholder: "이름을 입력해주세요", content: $name)
                    .padding(.bottom, 40)
                
                CommonSignUpTextField(title: "전화번호", placeholder: "전화번호를 입력해주세요", content: $phoneNumber)
                    .padding(.bottom, 40)
                
                Text("생년월일")
                    .foregroundStyle(Color.gray)
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                
                Button {
                    isDatePickerPresented.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color.white)
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                            .frame(height: 50)
                        
                        Text("\(birthDate.toString())")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)
                    }
                }
                .padding(.bottom, 40)
                
                if isDatePickerPresented {
                    DatePicker(
                        "",
                        selection: $birthDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.wheel)
                    .padding(.horizontal)
                }
                
                
                if viewModel.role == .mentor {
                    Text("과목")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        ForEach(subjectRows, id: \.self) { row in
                            HStack(spacing: 8) {
                                ForEach(row, id: \.self) { subject in
                                    Button {
                                        selectedSubjects[subject] = !(selectedSubjects[subject] ?? false)
                                    } label: {
                                        Text(subject)
                                            .font(.system(size: 15))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 30)
                                            .background(Color.white)
                                            .foregroundColor(Color.black)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue, lineWidth: 2)
                                                    .opacity(selectedSubjects[subject] ?? false ? 1 : 0)
                                            )
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("학년")
                        .foregroundStyle(Color.gray)
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                    
                    Menu {
                        ForEach(options, id: \.self) { option in
                            Button(option) { selectedGrade = option }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(Color.white)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .frame(height: 50)
                            
                            Label(selectedGrade, systemImage: "chevron.down")                .foregroundStyle(Color.gray)
                                .font(.system(size: 20))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 14)
                        }
                    }
                }
                
                Spacer()
                
            }
            
            Spacer()
            
            CommonSignUpButton(text: "완료", isFilled: $isFilled) {
                // viewmodel에 데이터 전송
                print("nextPage")
                
                // viewModel 호출 후 화면 전환 (어떤 방식이 더 효율적인지는 아직 모르겠음)
                isSuceed = true
            }
        }
        .padding()
        .background(.backgroundws)
        .navigationDestination(isPresented: $isSuceed) {
            ContentView()
        }
    }
}

#Preview {
    SignUpDetailProfileView()
        .environmentObject(SignUpViewModel())
}
