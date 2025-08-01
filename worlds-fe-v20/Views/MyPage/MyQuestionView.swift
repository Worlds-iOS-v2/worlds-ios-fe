//
//  MyQuestionView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/1/25.
//

import SwiftUI

struct MyQuestionView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var questions: [QuestionList] = []
    
    let dummyQuestionList: [QuestionList] = [
        QuestionList(
            id: 1,
            title: "SwiftUI에서 배경 색상 전체 적용 안 될 때",
            content: "ZStack을 사용하라는 말을 들었는데 잘 안되네요. 어떻게 배경을 전체에 적용하죠?",
            createdAt: "2025-08-01T09:30:00",
            isAnswered: true,
            answerCount: 3,
            category: .study,
            user: QuestionUser(
                id: 101,
                name: "서하",
                email: "seoha@example.com",
                role: false
            ),
            imageUrls: [
                "https://example.com/image/question1_1.png"
            ]
        ),
        QuestionList(
            id: 2,
            title: "Swift 네이밍 관련 질문 있어요",
            content: "프로퍼티 이름을 카멜케이스로 짓는 게 맞는 건가요? 코딩 컨벤션에 대해 궁금합니다.",
            createdAt: "2025-07-30T14:20:00",
            isAnswered: false,
            answerCount: 0,
            category: .free,
            user: QuestionUser(
                id: 102,
                name: "지민",
                email: "jimin@mail.com",
                role: false
            ),
            imageUrls: nil
        ),
        QuestionList(
            id: 3,
            title: "ViewModel에서 API 호출 시점 질문",
            content: "onAppear에서 fetch를 해도 될까요? 아니면 init에서 하는 편이 더 나을까요?",
            createdAt: "2025-07-28T18:45:00",
            isAnswered: true,
            answerCount: 5,
            category: .study,
            user: QuestionUser(
                id: 103,
                name: "영우",
                email: "youngwoo@worlds.io",
                role: true
            ),
            imageUrls: [
                "https://example.com/image/question3_1.png",
                "https://example.com/image/question3_2.png"
            ]
        ),
        QuestionList(
            id: 4,
            title: "자유게시판에 글 쓰는 연습입니다",
            content: "이 게시판은 테스트용으로 마음껏 글 올려도 되나요?",
            createdAt: "2025-07-26T16:00:00",
            isAnswered: false,
            answerCount: 1,
            category: .free,
            user: QuestionUser(
                id: 104,
                name: "민준",
                email: "minjun@domain.com",
                role: false
            ),
            imageUrls: nil
        ),
        QuestionList(
            id: 5,
            title: "iOS NavigationLink 디버깅 도움 요청합니다",
            content: "탭 했을 때 화면이 안 넘어가거나 이상한 화면이 뜰 때, 디버깅 방법 추천해주실 분~?",
            createdAt: "2025-07-25T22:10:00",
            isAnswered: true,
            answerCount: 2,
            category: .study,
            user: QuestionUser(
                id: 105,
                name: "지원",
                email: "jiwon@sample.com",
                role: true
            ),
            imageUrls: [
                "https://example.com/image/question5_1.png"
            ]
        )
    ]

    
    var body: some View {
        ZStack {
            Color.backgroundws
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(dummyQuestionList) { question in
                        NavigationLink(destination: QuestionDetailView(questionId: question.id, viewModel: QuestionViewModel())
                            .environmentObject(CommentViewModel())) {
                                QuestionCard(question: question)
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
