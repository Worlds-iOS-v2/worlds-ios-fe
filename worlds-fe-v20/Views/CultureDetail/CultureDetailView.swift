//
//  CultureDetailView.swift
//  worlds-fe-v20
//
//  Created by soy on 7/29/25.
//

import SwiftUI

struct CultureDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = CultureDetailViewModel()
    
    var body: some View {
        ZStack {
            Color(.sub2Ws)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    Text("이번주 소식")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    
                    AutoSlideViewWithTimer(datas: viewModel.dummyEventData)
                        .frame(height: 300)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    
                    Text("정부 프로그램")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    CultureSlideView<GovernmentProgram>(datas: viewModel.dummyGovernmentData)
                        .frame(height: 150)
                        .padding(.horizontal, 24)
                    
                    Text("한국어 교육 프로그램")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    CultureSlideView<KoreanProgram>(datas: viewModel.dummyKoreanData)
                        .frame(height: 150)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("문화행사정보")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    CultureDetailView()
}
