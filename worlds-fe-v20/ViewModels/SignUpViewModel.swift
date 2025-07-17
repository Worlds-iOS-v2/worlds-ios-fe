//
//  SignUpViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import SwiftUI

final class SignUpViewModel: ObservableObject {
    @Published var role: UserRole = .none
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var birthDate = Date()
    
    // 추후 회원가입 함수
}
