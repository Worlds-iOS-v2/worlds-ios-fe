//
//  MainView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    
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
                let dateString = formatDate(targetDate)
                result[weekday] = viewModel.attendanceList.contains(dateString)
            } else {
                result[weekday] = false
            }
        }
        
        return result
    }
    
    var textColor: Color = .mainfontws
    
    // 더미 데이터
    let scheduleEvent = ScheduleEvent(
        date: "12월 23일",
        dayOfWeek: "수",
        description: "일정이 없습니다."
    )
    
    let lunchData = MealInfo(
        mealType: "오늘의 중식",
        menuItems: [
            "흑미밥",
            "된장찌개",
            "제육볶음",
            "배추김치",
            "과일샐러드",
            "초코우유"
        ]
    )
    
    let dinnerData = MealInfo(
        mealType: "오늘의 석식",
        menuItems: [
            "현미밥",
            "미역국",
            "닭강정",
            "깍두기",
            "요구르트",
            "아이스홍시"
        ]
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Image(.schoolws)
                    
                    Text("00고등학교")
                        .font(.pretendard(.bold, size: 24))
                    
                    Spacer()
                    
                    ProfileButton()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                Text("학사 일정")
                    .font(.pretendard(.bold, size: 20))
                    .padding(.horizontal, 24)
                
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 8) {
                        Text(scheduleEvent.date)
                            .font(.pretendard(.semiBold, size: 12))
                        
                        Text(scheduleEvent.dayOfWeek)
                            .font(.pretendard(.bold, size: 30))
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scheduleEvent.description)
                            .font(.pretendard(.regular, size: 16))
                            .foregroundStyle(Color.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.sub2Ws)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.mainws, lineWidth: 1)
                        )
                )
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                
                Text("급식 정보")
                    .font(.pretendard(.bold, size: 20))
                    .padding(.bottom, 8)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                HStack(spacing: 0) {
                    // 오늘의 중식
                    VStack(spacing: 16) {
                        Text(lunchData.mealType)
                            .font(.pretendard(.bold, size: 14))
                        
                        VStack(spacing: 8) {
                            ForEach(lunchData.menuItems, id: \.self) { item in
                                Text(item)
                                    .font(.pretendard(.regular, size: 14))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 구분선
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                    
                    // 오늘의 석식
                    VStack(spacing: 16) {
                        Text(dinnerData.mealType)
                            .font(.pretendard(.bold, size: 14))
                        
                        VStack(spacing: 8) {
                            ForEach(dinnerData.menuItems, id: \.self) { item in
                                Text(item)
                                    .font(.pretendard(.regular, size: 14))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.mainws, lineWidth: 1)
                        )
                )
                .padding(.vertical, 10)
                .padding(.horizontal, 24)

                
                Text("최신글")
                    .font(.pretendard(.bold, size: 20))
                    .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    ForEach(viewModel.posts.prefix(5), id: \.self) { post in
                        NavigationLink(destination: QuestionDetailView(questionId: post.id, viewModel: QuestionViewModel())) {
                            
                            HStack(spacing: 40){
                                Text("\(post.category.displayName)")
                                    .font(.pretendard(.medium, size: 16))
                                    .foregroundStyle(Color.black)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("\(post.title)")
                                    .font(.pretendard(.regular, size: 16))
                                    .foregroundStyle(Color.black)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.mainws, lineWidth: 1)
                        )
                )
                .foregroundStyle(textColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                
                Text("대외활동")
                    .font(.pretendard(.bold, size: 20))
                    .padding(.horizontal, 24)
                
                AutoSlideViewWithTimer(datas: viewModel.eventPrograms, isLoading: viewModel.isLoading)
                    .frame(height: 340)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            Task {
                await viewModel.fetchAllDatas()
            }
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
