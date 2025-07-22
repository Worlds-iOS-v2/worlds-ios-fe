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
    @State private var selectedCategory: String = "전체"
    
    @ObservedObject var viewModel: QuestionViewModel
    
    let categories = ["전체", "학습", "자유"]
    let categoryMap = ["전체": "all", "학습": "study", "자유": "free"]
    
    var filteredQuestions: [QuestionList] {
        if selectedCategory == "전체" {
            return viewModel.questions
        } else {
            return viewModel.questions.filter {
                $0.category.displayName == selectedCategory
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(red: 0.94, green: 0.96, blue: 1.0).ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("게시판")
                            .font(.system(size: 26, weight: .semibold))
                            .padding(.top, 4)
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .bold))
                            .onTapGesture {
                                showingCreateQuestionSheet = true
                            }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    
                    // 검색 바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("검색", text: .constant(""))
                            .font(.system(size: 16))
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(selectedCategory == category ? .white : .gray)
                                        .frame(width: 66, height: 36)
                                        .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                        .cornerRadius(16)
                                        .shadow(color: selectedCategory == category ? Color.blue.opacity(0.1) : .clear, radius: 2, y: 2)
                                }
                            }
                            
                            Menu {
                                Button("최신순", action: {})
                                Button("조회순", action: {})
                                //상세
                            } label: {
                                HStack {
                                    Text("정렬 기준")
                                        .font(.system(size: 16))
                                    Image(systemName: "chevron.down")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.07), radius: 1, y: 1)
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.vertical, 8)
                    }
                    
                    // 게시물 목록
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(filteredQuestions) { question in
                                NavigationLink(destination: QuestionDetailView(question: question)) {
                                    QuestionCard(question: question)
                                        .padding(.horizontal, 15)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
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
                                    let categoryKey = categoryMap[selectedCategory] ?? "free"
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
                .onAppear {
                    viewModel.loadDummyData()
                    //                        Task {
                    //                            await viewModel.fetchQuestions()
                    //                        }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct QuestionCard: View {
    let question: QuestionList
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 카테고리
            Text(question.category.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray))
                .padding(.top, 8)
            // 제목
            Text(question.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 2)
            // 내용
            Text(question.content)
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray2))
                .lineLimit(1)
                .padding(.bottom, 6)
            
            HStack {
                // 답변 수
                if question.answerCount > 0 {
                    Text("답변 \(question.answerCount)개")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

extension Category {
    var displayName: String {
        switch self {
        case .all: return "전체"
        case .study: return "학습"
        case .free: return "자유"
        }
    }
}
