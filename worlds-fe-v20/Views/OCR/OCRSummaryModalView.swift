//
//  OCRSummaryView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/30/25.
//

import SwiftUI

struct OCRSummaryModalView: View {
    @EnvironmentObject private var viewModel: OCRViewModel

    var textColor: Color = .mainfontws

    var body: some View {
        ZStack {
            Color(.background1Ws)
                .ignoresSafeArea()
            
            if viewModel.isSummaryLoading {
                // 로딩 중일 때 프로그레스 뷰 표시
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .mainws))
                    
                    Text("개념을 분석하고 있습니다...")
                        .font(.pretendard(.regular, size: 18))
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView() {
                    VStack(alignment: .leading) {
                        Text("핵심 개념")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundStyle(textColor)
                            .padding(.top, 20)
                        
                        
                        Text(viewModel.keyConcept)
                            .font(.pretendard(.medium, size: 20))
                            .foregroundStyle(textColor)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                        
                        Text("문제 요약")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundStyle(textColor)

                        Text(viewModel.summary)
                            .font(.pretendard(.medium, size: 20))
                            .foregroundStyle(textColor)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                        
                        Text("힌트")
                            .font(.pretendard(.bold, size: 24))
                            .foregroundStyle(textColor)

                        Text(viewModel.solution)
                            .font(.pretendard(.medium, size: 20))
                            .foregroundStyle(textColor)
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
    }
}

#Preview {
    OCRSummaryModalView()
        .environmentObject(OCRViewModel())
}
