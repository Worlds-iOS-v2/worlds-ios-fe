//
//  MainViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

final class MainViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var posts: [QuestionList] = []
    @Published var attendanceList: [String] = []
    
    @Published var eventPrograms: [EventProgram] = []
    @Published var govermentPrograms: [GovernmentProgram] = []
    // @Published var koreanPrograms: [KoreanProgram] = []
    @Published var isLoading: Bool = false
    
    // 데이터 로드 상태 (한 번만 로드하기 위한 플래그)
    private var hasLoadedPosts = false
    private var hasLoadedAttendance = false
    private var hasLoadedCulture = false

    func getUsername() -> String {
        guard let username = UserDefaults.standard.string(forKey: "username") else {
            return "사용자"
        }
        return username
    }
    
    func fetchAllDatas() async {
        await fetchLatestPosts()
        await fetchAttendanceList()
        await fetchCultureInfo()
    }
    
    @MainActor
    func fetchLatestPosts() async {
        guard !hasLoadedPosts else {
            print("📦 게시글 이미 로드됨 - 스킵")
            return
        }
        
        do {
            let posts = try await APIService.shared.fetchQuestions()
            self.posts = posts
            self.hasLoadedPosts = true
            self.errorMessage = nil
        } catch {
            print("❌ fetchLatestPosts 에러 발생:", error)
            self.errorMessage = "질문 최신 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func fetchAttendanceList() async {
        guard !hasLoadedAttendance else {
            print("📦 출석 정보 이미 로드됨 - 스킵")
            return
        }
        
        do {
            let attendanceData = try await UserAPIManager.shared.getAttendanceList()
            self.attendanceList = attendanceData.attendanceDates ?? []
            self.hasLoadedAttendance = true
            self.errorMessage = nil
        } catch {
            print("❌ fetchAttendanceList 에러 발생:", error)
            self.errorMessage = "출석 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func fetchCultureInfo() async {
        guard !hasLoadedCulture else {
            print("📦 문화 정보 이미 로드됨 - 스킵")
            return
        }
        
        isLoading = true
        
        do {
            let info = try await UserAPIManager.shared.getCultureInfo()
            self.eventPrograms = info.eventData
            self.govermentPrograms = info.governmentData
            // self.koreanPrograms = info.koreanData
            self.hasLoadedCulture = true
            self.errorMessage = nil
        } catch {
            print("❌ fetchCultureInfo 에러 발생:", error)
            self.errorMessage = "문화 정보 목록을 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearAllData() { // 로그아웃 할 경우 데이터 클리어
        posts = []
        attendanceList = []
        eventPrograms = []
        govermentPrograms = []
        // koreanPrograms = []
        hasLoadedPosts = false
        hasLoadedAttendance = false
        hasLoadedCulture = false
    }
}
