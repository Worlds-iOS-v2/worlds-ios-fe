//
//  MainView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    @StateObject var cultureViewModel = CultureDetailViewModel()

    @State private var selectedDate = Date()
    
    // 출석 여부를 계산하는 computed property
    private var attendanceData: [Int: Bool] {
        var result: [Int: Bool] = [:]

        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        
        for weekday in 1...7 {
            let daysToAdd = weekday - currentWeekday
            if let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) {
                let dateString = formatDate(targetDate) // "2025-08-18" 형식
                result[weekday] = viewModel.attendanceList.contains(dateString)
            } else {
                result[weekday] = false
            }
        }
        
        return result
    }
    
    var body: some View {
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
                               .fill(.thickMaterial) // 또는 .regularMaterial, .thickMaterial
                               .opacity(0.8)
                               .frame(height: 160)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(height: 120)
                            .padding(.horizontal, 12)
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
                
                AutoSlideViewWithTimer(datas: cultureViewModel.eventPrograms, isLoading: cultureViewModel.isLoading)
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
            Task { await viewModel.fetchLatestPosts() }
            Task { await cultureViewModel.fetchCultureInfo() }
            Task { await viewModel.fetchAttendanceList() }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    MainView(viewModel: MainViewModel())
}
