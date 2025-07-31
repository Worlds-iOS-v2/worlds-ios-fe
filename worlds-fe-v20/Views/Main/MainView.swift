//
//  MainView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    
    @State private var selectedDate = Date()
    @State private var attendanceData: [Int: Bool] = [:]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("안녕하세요! \(viewModel.getUsername())님")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }
                .background(
                    Rectangle()
                        .fill(Color.sub2Ws)
                        .padding(.bottom, 60)
                        .padding(.top, -120)
                )
                .padding(.vertical, 40)
                
                HStack() {
                    Text("이번주 소식")
                        .font(.system(size: 27))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    
                    NavigationLink(destination: CultureDetailView()) {
                        Text("더보기 >")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.mainws)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(
                Rectangle()
                    .fill(Color.sub2Ws)
                    .padding(.bottom, 60)
                    .padding(.top, -120)
            )
            .padding(.vertical, 40)
            
            Text("이번주 소식")
                .font(.system(size: 27))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            
            AutoSlideViewWithTimer()
                .frame(height: 300)
                .padding(.horizontal, 24)
            
            Text("최신글")
                .font(.system(size: 27))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            
            VStack(spacing: 16) {
                Spacer()
                
                ForEach(viewModel.posts.prefix(5), id: \.self) { post in
                    Button {
                        // 해당 게시물로 화면 이동
                    } label: {
                        HStack(spacing: 40){
                            Text("\(post.category.displayName)")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.black)
                                .frame(width: 40, alignment: .leading)
                            
                            Text("\(post.title)")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.black)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
            .padding(.bottom, 100)
            .background(Color.white)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                try await viewModel.fetchLatestPosts()
            }
        }
    }
}

#Preview {
    MainView(viewModel: MainViewModel())
}
