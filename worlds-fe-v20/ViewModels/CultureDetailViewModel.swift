//
//  CultureDetailViewModel.swift
//  worlds-fe-v20
//
//  Created by soy on 7/29/25.
//

import SwiftUI

final class CultureDetailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var birthDate = Date()
}
