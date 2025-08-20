//
//  AttendanceRowView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

struct AttendanceRowView: View {
    let weekday: Int
    let isAttended: Bool
    let isToday: Bool
    
    var body: some View {
            VStack(spacing: 16) {
                if isToday {
                    ZStack {
                        Circle()
                            .fill(.mainws.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(getWeekdayString(for: weekday))
                            .font(.pretendard(.bold, size: 16))
                            .foregroundColor(.mainfontws)
                    }
                } else {
                    Text(getWeekdayString(for: weekday))
                        .font(.pretendard(.medium, size: 16))
                        .foregroundColor(.mainfontws)
                        .frame(width: 40, height: 40)
                }
                
                if isAttended {
                    Image("bookws")
                        .font(.system(size: 20))
                        .frame(width: 20, height: 20)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: 20, height: 20)
                }
            }
    }
    
    // 사용자 언어 설정에 따라 요일 문자열 반환
    // 나중에 extension 영역으로 이동
    private func getWeekdayString(for weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        let daysToAdd = weekday - currentWeekday
        
        if let targetDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) {
            return formatter.string(from: targetDate)
        }
        
        let defaultWeekdays = ["일", "월", "화", "수", "목", "금", "토"]
        return defaultWeekdays[weekday - 1]
    }
}

#Preview {
    AttendanceRowView(weekday: 1, isAttended: true, isToday: true)
}
