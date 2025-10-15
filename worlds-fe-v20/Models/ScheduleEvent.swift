//
//  ScheduleEvent.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/16/25.
//

import Foundation

// 학사 일정 모델
struct ScheduleEvent: Identifiable {
    let id = UUID()
    let date: String
    let dayOfWeek: String
    let description: String
}
