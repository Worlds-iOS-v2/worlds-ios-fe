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
    @State private var searchText: String = ""
    
    @State private var selectedCategory: Category = .all
    
    @ObservedObject var viewModel: QuestionViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    let categories: [Category] = [.all, .study, .free]
    
    var filteredQuestions: [QuestionList] {
        let categoryFiltered = selectedCategory == .all
        ? viewModel.questions
        : viewModel.questions.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var textColor: Color = .mainfontws
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background2Ws
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("게시판")
                        .font(.bmjua(.regular, size: 27))
                        .foregroundStyle(textColor)
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
                    
                    TextField("검색", text: $searchText)
                        .font(.bmjua(.regular, size: 16))
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                
                // 카테고리 선택
                HStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack() {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category.displayName)
                                        .font(.bmjua(.regular, size: 18))
                                        .foregroundColor(selectedCategory == category ? .white : .gray)
                                        .frame(width: 66, height: 36)
                                        .background(selectedCategory == category ? Color.mainws : Color(.systemGray5))
                                        .cornerRadius(16)
                                        .shadow(color: selectedCategory == category ? Color.blue.opacity(0.1) : .clear, radius: 2, y: 2)
                                }
                            }
                        }
                    }
                    
                    Menu {
                        Button("최신순", action: {})
                        Button("조회순", action: {})
                    } label: {
                        HStack {
                            Text("정렬 기준")
                                .font(.bmjua(.regular, size: 16))
                                .foregroundStyle(textColor)
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(textColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.07), radius: 1, y: 1)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                
                // 게시물 목록
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(filteredQuestions) { question in
                            
                            NavigationLink(destination: QuestionDetailView(questionId: question.id, viewModel: viewModel)
                                .environmentObject(CommentViewModel())) {
                                    QuestionCard(question: question, thumbnailURLString: viewModel.thumbnails[question.id])
                                        .task { await viewModel.loadThumbnailIfNeeded(for: question.id) }
                                }
                                .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                }
                .refreshable {
                    await viewModel.fetchQuestions()
                }
                
                Spacer()
            }
            
            // 질문 작성 뷰
            .fullScreenCover(isPresented: $showingCreateQuestionSheet) {
                CreateQuestionView(
                    title: $newQuestionTitle,
                    content: $newQuestionContent,
                    isPresented: $showingCreateQuestionSheet,
                    isCreating: $isCreatingQuestion,
                    errorMessage: $createQuestionError,
                    onSubmit: { images, category in
                        isCreatingQuestion = true
                        Task {
                            do {
                                let result = try await APIService.shared.createQuestion(
                                    title: newQuestionTitle,
                                    content: newQuestionContent,
                                    category: category,
                                    images: images.map { $0.jpegData(compressionQuality: 0.7)! }
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
                Task {
                    await viewModel.fetchQuestions()
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task { await viewModel.fetchQuestions() }
            }
        }
    }
}

struct QuestionCard: View {
    let question: QuestionList
    let thumbnailURLString: String?
    
    private var thumbnailURL: URL? {
        guard let s = thumbnailURLString, let url = URL(string: s) else { return nil }
        return url
    }
    
    var textColor: Color = .mainfontws
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: texts
            VStack(alignment: .leading, spacing: 6) {
                Text(question.category.displayName)
                    .font(.bmjua(.regular, size: 14))
                    .foregroundColor(Color(.systemGray))
                    .padding(.top, 8)
                
                HStack(alignment: .center, spacing: 8) {
                    Text(question.title)
                        .font(.bmjua(.regular, size: 20))
                        .foregroundColor(textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if question.answerCount > 0 {
                        Text("답변 \(question.answerCount)개")
                            .font(.bmjua(.regular, size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(Color.mainws)
                            .cornerRadius(14)
                    }
                    Spacer()
                }
                .padding(.top, 2)
                
                Text(question.content)
                    .font(.bmjua(.regular, size: 16))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(2)
                    .padding(.bottom, 6)
                
                Spacer(minLength: 0)
            }
            
            // Right: thumbnail
            if let url = thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 72, height: 72)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray3))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.bmjua(.regular, size: 20))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
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
