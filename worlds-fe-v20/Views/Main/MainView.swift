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
                    VStack {
                        Text("안녕하세요! \(viewModel.getUsername())님")
                            .font(.system(size: 27))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        
                        // 출석 체크 화면
                        ZStack() {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                            
                            HStack() {
                                ForEach(1...7, id: \.self) { weekday in
                                    AttendanceRowView(
                                        weekday: weekday,
                                        isAttended: attendanceData[weekday] ?? true,
                                        isToday: weekday == Calendar.current.component(.weekday, from: Date()))
                                }
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
                            NavigationLink(destination: QuestionDetailView(questionId: post.id, viewModel: QuestionViewModel())) {
                                
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
                .padding(.bottom, 100)
                .background(Color.white)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                Task {
                    await viewModel.fetchLatestPosts()
                }
            }
        }
    }
}

#Preview {
    MainView(viewModel: MainViewModel())
}
