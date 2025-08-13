//
//  CultureDetailViewModel.swift
//  worlds-fe-v20
//
//  Created by soy on 7/29/25.
//

import SwiftUI

final class CultureDetailViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var userInfo: User?

    @Published var eventPrograms: [EventProgram] = []
    @Published var govermentPrograms: [GovernmentProgram] = []
    @Published var koreanPrograms: [KoreanProgram] = []
    @Published var isLoading: Bool = false
    
    @MainActor
    func fetchCultureInfo() async {
        isLoading = true
        
        do {
            let info = try await UserAPIManager.shared.getCultureInfo()
            self.eventPrograms = info.eventData
            self.govermentPrograms = info.governmentData
            self.koreanPrograms = info.koreanData
            self.errorMessage = nil
        } catch {
            print("❌ fetchCultureInfo 에러 발생:", error)
            self.errorMessage = "문화 정보 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
