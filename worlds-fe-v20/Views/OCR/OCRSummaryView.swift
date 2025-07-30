//
//  OCRSummaryView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/30/25.
//

import SwiftUI

struct OCRSummaryView: View {
    @EnvironmentObject private var viewModel: OCRViewModel

    var body: some View {
        ZStack {
            Color(.backgroundws)
                .ignoresSafeArea()
            
            if viewModel.isSummaryLoading {
                // 로딩 중일 때 프로그레스 뷰 표시
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .mainws))
                    
                    Text("개념을 분석하고 있습니다...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView() {
                    VStack(alignment: .leading) {
                        Text("핵심 개념")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .padding(.top, 20)
                        
                        
                        Text(viewModel.keyConcept)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                        
                        Text("문제 요약")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.black)
                        
                        Text(viewModel.summary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                        
                        Text("힌트")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.black)
                        
                        Text(viewModel.solution)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            Task {
                try await viewModel.fetchOCRSolution()
            }
        }
    }
}

#Preview {
    OCRSummaryView()
        .environmentObject(OCRViewModel())
}
