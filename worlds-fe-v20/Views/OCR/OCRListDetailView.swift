//
//  OCRListDetailView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/19/25.
//

import SwiftUI
import UIKit

struct OCRListDetailView: View {
    @State private var expandSummaryAccordionView = false
    @State private var contentHeight: CGFloat = 0

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var ocrContent: OCRList
        
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
                //                Image(uiImage: ocrContent.)
                //                    .resizable()
                //                    .scaledToFit()
                //                    .frame(maxHeight: 300)
                //                    .cornerRadius(12)
                //                    .shadow(radius: 5)
                
                // OCR 결과 표시
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<ocrContent.originalText.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(ocrContent.originalText[index])
                                    .font(.body)
                                    .foregroundColor(.black)
                                
                                Text(ocrContent.translatedText[index])
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
                
                ScrollView() {
                    VStack(alignment: .leading) {
                        Text("핵심 개념")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .padding(.top, 20)
                        
                        
                        Text(ocrContent.keyConcept)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                        
                        Text("문제 요약")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.black)
                        
                        Text(ocrContent.summary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                        
                        Text("힌트")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.black)
                        
                        Text(ocrContent.solution)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                            )
                            .padding(.bottom, 32)
                    }
                    .padding()
                }
                .frame(height: expandSummaryAccordionView ? nil : 0)
                .background(.backgroundws)
            }
            .padding()
            .navigationTitle("OCR 리스트")
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
        }
    }
}

#Preview {
    OCRResultView(selectedImage: UIImage(systemName: "photo") ?? UIImage())
        .environmentObject(OCRViewModel())
}
