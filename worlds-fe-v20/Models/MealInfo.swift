//
//  MealInfo.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/16/25.
//

import Foundation

// 급식 메뉴 모델
struct MealInfo: Identifiable, Hashable {
    let id = UUID()
    let mealType: String
    let menuItems: [String]
}
