//
//  OCRListViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

import SwiftUI

final class OCRListViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var ocrList: [OCRList] = []
    
    @MainActor
    func fetchMyOCRList() async {
        let userID = UserDefaults.standard.integer(forKey: "userId")
        if userID == 0 { return }
        
        do {
            let ocrList = try await UserAPIManager.shared.getOCRList(userID: userID)
            self.ocrList = ocrList
            // print("OCR: \(ocrList)")
            self.errorMessage = nil
        } catch {
            print("ocrList 에러 발생:", error)
            self.errorMessage = "OCR 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
}
