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
        ZStack {
            VStack {
                Text("안녕하세요! \(viewModel.name)님")
                    .font(.system(size: 27, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, -50)
                
                // 출석 체크 화면
                ZStack() {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 360, height: 120)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                    
                    HStack(spacing: 12) {
                        ForEach(1...7, id: \.self) { weekday in
                            AttendanceRowView(
                                weekday: weekday,
                                isAttended: attendanceData[weekday] ?? true,
                                isToday: weekday == Calendar.current.component(.weekday, from: Date()))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Text("이번주 소식")
                    .font(.system(size: 27))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                
                Text("인기글")
                    .font(.system(size: 27))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            .background(Color.gray)
        }
        .background(Color.white)
        
    }
}

#Preview {
    MainView(viewModel: MainViewModel())
}
