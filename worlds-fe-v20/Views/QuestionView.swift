//
//  QuestionView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//

import SwiftUI

struct QuestionView: View {
    @State private var showingCreateQuestionSheet = false
    @State private var newQuestionTitle = ""
    @State private var newQuestionContent = ""
    @State private var isCreatingQuestion = false
    @State private var createQuestionError: String?
    @State private var selectedCategory: String = "전체 보기"
    
    @ObservedObject var viewModel: QuestionViewModel
    //    @ObservedObject var userViewModel: UserViewModel //role==mentee일때 활성화
    
    let categories = ["전체 보기", "학습 게시판", "자유 게시판"]
    let categoryMap = ["전체 보기": "all", "학습 게시판": "study", "자유 게시판": "free"]
    
    var filteredQuestions: [QuestionList] {
        if selectedCategory == "전체 보기" {
            return viewModel.questions
        } else {
            return viewModel.questions.filter {
                $0.category.rawValue == selectedCategory
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                
                VStack(spacing: 0) {
                    
                    HStack {
                        Image("WorldStudy")
//                            .resizable()
//                            .frame(width: 30, height: 18)
                        Spacer()
                            .toolbar {
//                                if userViewModel.role == "mentee" {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("질문하기") {
                                            showingCreateQuestionSheet = true
                                        }
                                    }
                                }
//                            }
                            }
                            .padding(.horizontal, 25)
                            .padding(.top, 15)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            headerText
                            categoryScrollView
                            questionListView
                        }
                    }
                    
                    .onAppear {
                        viewModel.loadDummyData() //테스트 용 - 이후 삭제
//                        Task {
//                            await viewModel.fetchQuestions()
//                        }
                    }
                    
                    .fullScreenCover(isPresented: $showingCreateQuestionSheet) {
                        CreateQuestionView(
                            title: $newQuestionTitle,
                            content: $newQuestionContent,
                            isPresented: $showingCreateQuestionSheet,
                            isCreating: $isCreatingQuestion,
                            errorMessage: $createQuestionError,
                            onSubmit: { selectedCategoryKey, _ in
                                isCreatingQuestion = true
                                Task {
                                    do {
                                        let categoryKey = categoryMap[selectedCategory] ?? "free" // 기본값
                                        let result = try await APIService.shared.createQuestion(
                                            title: newQuestionTitle,
                                            content: newQuestionContent,
                                            category: categoryKey,
                                            images: nil
                                        )
                                        if result {
                                            await viewModel.fetchQuestions()
                                            newQuestionTitle = ""
                                            newQuestionContent = ""
                                            showingCreateQuestionSheet = false
                                        } else {
                                            createQuestionError = "질문 등록 실패"
                                        }
                                    } catch {
                                        createQuestionError = "오류: \(error.localizedDescription)"
                                    }
                                    isCreatingQuestion = false
                                }
                            }
                        )
                    }
                }
            }
        }
        
        private var headerText: some View {
            Text("궁금한 게 있으면\n멘토 친구들에게 물어보세요 🌱")
                .font(.title3)
                .foregroundColor(.black)
                .fontWeight(.bold)
                .padding(.leading, 25)
                .padding(.top, 15)
        }
        
        private var categoryScrollView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.orange : Color(.systemGray5))
                                .foregroundColor(selectedCategory == category ? .white : .black)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 8)
            }
        }
        
        private var questionListView: some View {
            List {
                ForEach(filteredQuestions) { question in
                    NavigationLink(destination: QuestionDetailView(question: question)) {
                        QuestionRow(question: question)
                    }
                }
            }
        }
    }
    
    struct QuestionRow: View {
        let question: QuestionList
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(question.title)
                    .font(.headline)
                Text(question.content)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                Text(" \(question.answerCount)개의 답변")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
    }
