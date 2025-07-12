//
//  QuestionDetailView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
// TODO: 이미지 등록 안댄다...zz

import SwiftUI

struct QuestionDetailView: View {
    let question: QuestionList
//    @State var answer: [Answer] = []
//    @State var attatchmentImage: [Attachment] = []
    
    @State private var goToCreateAnswerView = false
    
    var body: some View {
        VStack(spacing:0) {
            VStack(alignment: .leading, spacing: 15) {
                Text(question.title)
                    .font(.title)
                    .bold()
                    .padding(.top, 10)
                
                HStack {
                    Text("작성일: \(question.createdAt)")
                    Text("작성자: \(question.user.name ?? "알 수 없는 사용자")")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                Divider()
                
                Text(question.content)
                    .font(.body)
                    .padding(.vertical)

                Text("답변")
                    .font(.title3)
                    .bold()
            }
            .padding(.top, 10)
            
            Divider()
            
//            ScrollView {
//                VStack(alignment: .leading, spacing: 15) {
//                    if answer.isEmpty {
//                        Text("아직 답변이 없습니다.")
//                            .foregroundColor(.gray)
//                    } else {
//                        ForEach(answer) { answer in
//                            VStack(alignment: .leading, spacing: 8) {
//                                Text("\(answer.user.name) 멘토")
//                                    .font(.subheadline)
//                                    .bold()
//                                Text(answer.content)
//                                    .font(.body)
//                                Divider()
//                            }
//                        }
//                    }
//                }
//                .padding()
//            }
            
            Spacer()
            
            Button(action: {
                goToCreateAnswerView = true
            })
            {
                Text("답변 작성하기")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding()
                    .frame(width: 150)
                    .background(Color("darkbrown"))
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.black, lineWidth: 0))
                
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20) //양쪽 패딩값
        .padding(.bottom, 20)
//        .onAppear {
//            Task {
//                do {
//                    self.answer = try await APIService.shared.fetchAnswers(questionId: question.id)
//                } catch {
//                    print("답변 로딩 실패: \(error.localizedDescription)")
//                }
//            }
//        }
    }
}
