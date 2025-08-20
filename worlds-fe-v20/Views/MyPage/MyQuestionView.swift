//
//  MyQuestionView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/1/25.
//

import SwiftUI

struct MyQuestionView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var questions: [QuestionList]
    
    var body: some View {
        ZStack {
            Color.background2Ws
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(questions) { question in
                        NavigationLink(destination: QuestionDetailView(questionId: question.id, viewModel: QuestionViewModel())
                            .environmentObject(CommentViewModel())) {
                                QuestionCard(question: question, thumbnailURLString: nil)
                            }
                            .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }
            .navigationTitle("내가 쓴 글")
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
}
