//
//  AppState.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/8/25.
//

import SwiftUI

enum AppFlowState {
    case login
    case signUp
    case main
}

final class AppState: ObservableObject {
    @Published var flow: AppFlowState = .login
}
