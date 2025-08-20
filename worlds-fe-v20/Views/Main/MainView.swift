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
                let dateString = formatDate(targetDate) // "2025-08-18" 형식
                result[weekday] = viewModel.attendanceList.contains(dateString)
            } else {
                result[weekday] = false
            }
        }
        
        return result
    }
    
    var textColor: Color = .mainfontws
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack() {
                    VStack(alignment: .leading) {
                        Text("안녕하세요! \(viewModel.getUsername())님")
                            .font(.pretendard(.bold, size: 22))
                            .padding(.top, 28)
                        
                        Text("오늘 하루는 어떤가요?")
                            .font(.pretendard(.medium, size: 20))
                    }
                    
                    Spacer()
                    
                    Image("mainws")
                }
                .padding(.horizontal, 24)

                
                // 출석 체크 화면
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { weekday in
                        AttendanceRowView(
                            weekday: weekday,
                            isAttended: attendanceData[weekday] ?? true,
                            isToday: weekday == Calendar.current.component(.weekday, from: Date())
                        )
                        .frame(maxWidth: .infinity) // 각각을 균등 분배
                    }
                }
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.sub2Ws)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.mainws, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, -24)
                .padding(.bottom, 48)

                HStack() {
                    Text("이번주 소식")
                        .font(.pretendard(.bold, size: 24))
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    NavigationLink(destination: CultureDetailView(
                        eventPrograms: viewModel.eventPrograms,
                        govermentPrograms: viewModel.govermentPrograms,
                        koreanPrograms: viewModel.koreanPrograms
                    )) {
                        Text("더보기 >")
                            .font(.pretendard(.semiBold, size: 16))
                            .foregroundStyle(Color.mainfontws)
                            .padding(.bottom, 20)
                    }
                }
                .padding(.horizontal, 24)
                
                AutoSlideViewWithTimer(datas: viewModel.eventPrograms, isLoading: viewModel.isLoading)
                    .frame(height: 340)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                
                Text("최신글")
                    .font(.pretendard(.bold, size: 24))
                    .padding(.bottom, 20)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    ForEach(viewModel.posts.prefix(5), id: \.self) { post in
                        NavigationLink(destination: QuestionDetailView(questionId: post.id, viewModel: QuestionViewModel())) {
                            
                            HStack(spacing: 40){
                                Text("\(post.category.displayName)")
                                    .font(.pretendard(.medium, size: 20))
                                    .foregroundStyle(Color.black)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text("\(post.title)")
                                    .font(.pretendard(.regular, size: 18))
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.sub2Ws)
                        .padding(.horizontal, 24)
                )
            }
            .foregroundStyle(textColor)
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
