//
//  MainViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var birthDate = Date()
}
