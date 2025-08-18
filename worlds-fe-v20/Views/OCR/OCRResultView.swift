//
//  OCRResultView.swift
//  worlds-fe-v20
//
//  Created by soy on 7/22/25.
//

import SwiftUI
import UIKit

// OCR 결과 화면: 크롭된 이미지를 보여주고, OCR 결과 텍스트를 표시
struct OCRResultView: View {
    // 선택된(크롭된) 이미지
    let selectedImage: UIImage
    @State private var showingSummaryModalView = false
    @State private var showingCreateQuestionView = false
    @State private var expandSummaryAccordionView = false
    @State private var contentHeight: CGFloat = 0
    
    var isOCRList: Bool = false
    
    @State private var newQuestionTitle = ""
    @State private var newQuestionContent = ""
    @State private var isCreatingQuestion = false
    @State private var createQuestionError: String?
    @State private var searchText: String = ""

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    // 공유 OCRViewModel 사용
    @EnvironmentObject private var viewModel: OCRViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack(spacing: 15) {
                    Text("한국어")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.sub2Ws)
                        .cornerRadius(16)
                    
                    Image(systemName: "arrowshape.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.sub2Ws)
                        .padding()
                    
                    Text("영어")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.sub2Ws)
                        .cornerRadius(16)
                }
                
                // 선택된 이미지 표시
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)

                if viewModel.isOCRLoading {
                    // 로딩 중일 때 프로그레스 뷰 표시
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .mainws))
                        
                        Text("텍스트를 분석하고 있습니다...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(.backgroundws)
                    .cornerRadius(12)
                } else {
                    // OCR 결과 표시
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(0..<viewModel.originalText.count, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(viewModel.originalText[index])
                                        .font(.body)
                                        .foregroundColor(.black)
                                    
                                    Text(viewModel.translatedText[index])
                                        .font(.body)
                                        .foregroundColor(.mainws)
                                    
                                    Divider()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.backgroundws)
                    }
                    .cornerRadius(8)
                }
            
                if isOCRList {
                    Button {
                        withAnimation(.easeInOut) {
                            expandSummaryAccordionView.toggle()
                        }
                    } label: {
                        HStack {
                            Text("개념 확인")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(expandSummaryAccordionView ? 180 : 0))
                        }
                        .padding()
                        .background(.backgroundws)
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        OCRSummaryModalView()
                    }
                    .frame(height: expandSummaryAccordionView ? nil : 0)
                    .background(.backgroundws)
                } else {
                    
                    // 버튼들
                    HStack(spacing: 15) {
                        Button {
                            // performOCR()
                            showingSummaryModalView = true
                        } label: {
                            Text("개념 보기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.mainws)
                                .cornerRadius(16)
                        }
                        .disabled(viewModel.isOCRLoading)
                        
                        Button {
                            showingCreateQuestionView = true
                        } label: {
                            Text("질문하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.backgroundws)
                                .cornerRadius(16)
                        }
                        .disabled(viewModel.isOCRLoading)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("재촬영")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.backgroundws)
                                .cornerRadius(16)
                        }
                        .disabled(viewModel.isOCRLoading)
                    }
                }
            }
            .padding()
            .navigationTitle(isOCRList ? "OCR 리스트" : "OCR 결과")
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        appState.flow = .main
                    } label: {
                        Image(systemName: "house")
                            .foregroundColor(.mainws)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingSummaryModalView) {
                OCRSummaryModalView()
                    .environmentObject(viewModel)
            }
            .fullScreenCover(isPresented: $showingCreateQuestionView) {
                CreateQuestionView(
                    title: $newQuestionTitle,
                    content: $newQuestionContent,
                    isPresented: $showingCreateQuestionView,
                    isCreating: $isCreatingQuestion,
                    errorMessage: $createQuestionError,
                    initialImages: [selectedImage],
                    initialCategory: .study,
                    onSubmit: { images, category in
                        Task {
                            try await viewModel.createQuestion(title: newQuestionTitle, content: newQuestionContent, category: category, images: images)
                        }
                        showingCreateQuestionView = false
                    }
                )
            }
            .onAppear {
                Task {
                    try await viewModel.fetchOCR(selectedImage: selectedImage)
                }
            }
        }
    }
}

#Preview {
    OCRResultView(selectedImage: UIImage(systemName: "photo") ?? UIImage())
        .environmentObject(OCRViewModel())
}
