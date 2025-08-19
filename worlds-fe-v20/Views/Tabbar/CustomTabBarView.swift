//
//  CustomTabBarView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/19/25.
//

import SwiftUI

// MARK: - 커스텀 탭바 뷰
struct CustomTabBarView: View {
    @State private var selectedTab = 0
    @State private var showCameraView = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {                
                Color.background2Ws
                    .ignoresSafeArea(.all)
                
                TabView(selection: $selectedTab) {
                    MainView(viewModel: MainViewModel())
                        .tag(0)
                    
                    QuestionView(viewModel: QuestionViewModel())
                        .tag(1)
                    
                    ChatListView()
                        .tag(2)
                    
                    MyPageView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                CustomTabBar(
                    selectedTab: $selectedTab,
                    onCameraTapped: { showCameraView = true }
                )
                
                .navigationDestination(isPresented: $showCameraView) {
                    OCRCameraView()
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

// MARK: - 커스텀 탭바 컴포넌트
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var onCameraTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 홈
            TabBarButton(
                icon: "house",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            // 게시판
            TabBarButton(
                icon: "text.page",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            // 카메라 (중앙)
            CenterTabButton(isSelected: false, action: { onCameraTapped() })
            
            // 채팅
            TabBarButton(
                icon: "message",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            // 프로필
            TabBarButton(
                icon: "person",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 10)
        .padding(.bottom, -4)
    }
}

// MARK: - 일반 탭 버튼
struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .mainws : .gray)
                
                // 선택된 탭 인디케이터
                Circle()
                    .fill(isSelected ? Color.mainws : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 중앙 특별 탭 버튼 (카메라)
struct CenterTabButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .overlay(
                        Circle()
                        
                            .stroke(Color.mainws, lineWidth: 4) // 테두리
                            .frame(width: 80, height: 80)
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // 카메라 아이콘
                Image(.cameraws)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .offset(y: -25) // 위로 살짝 올리기
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - 탭 아이템 모델
struct TabItem {
    let icon: String
    let title: String
    var isCenter: Bool = false
    
    init(icon: String, title: String, isCenter: Bool = false) {
        self.icon = icon
        self.title = title
        self.isCenter = isCenter
    }
}
