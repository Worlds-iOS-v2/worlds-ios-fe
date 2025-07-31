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
                    
                    AutoSlideViewWithTimer()
                        .frame(height: 300)
                        .padding(.horizontal, 24)
                    
                    Text("정부 프로그램")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    
                    VStack(spacing: 12) {
                        Spacer()
                        
                        ForEach(0..<5, id: \.self) { _ in
                            Button {
                                // 해당 게시물로 화면 이동
                            } label: {
                                HStack(spacing: 40){
                                    Text("제목")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.black)
                                    
                                    Text("내용")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.black)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 48)
                            }
                        }
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.backgroundws)
                            .padding(.horizontal, 24)
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                    )
                }
                .padding(.bottom, 20)
                
                Text("한국어 교육 프로그램")
                    .font(.system(size: 27))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                VStack(spacing: 12) {
                    Spacer()
                    
                    ForEach(0..<5, id: \.self) { _ in
                        Button {
                            // 해당 게시물로 화면 이동
                        } label: {
                            HStack(spacing: 40){
                                Text("제목")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.black)
                                
                                Text("내용")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.black)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 48)
                        }
                    }
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.backgroundws)
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                )
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
