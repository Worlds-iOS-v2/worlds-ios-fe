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
    @State private var showFloatingMenu = false
    @State private var navigateToChat = false
    @State private var navigateToOCR = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background2Ws
                    .ignoresSafeArea(.all)
                
                TabView(selection: $selectedTab) {
                    MainView(viewModel: MainViewModel())
                        .tag(0)
                    
                    QuestionView(viewModel: QuestionViewModel())
                        .tag(1)
                    
                    OCRListView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 플로팅 메뉴가 열렸을 때 배경 딤처리
                if showFloatingMenu {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showFloatingMenu = false
                            }
                        }
                }
                
                VStack {
                    Spacer()
                    
                    // 플로팅 메뉴
                    if showFloatingMenu {
                        HStack {
                            Spacer()
                            FloatingMenuView(
                                onChatTapped: {
                                    withAnimation(.spring(response: 0.3)) {
                                        showFloatingMenu = false
                                    }
                                    navigateToChat = true
                                },
                                onOCRTapped: {
                                    withAnimation(.spring(response: 0.3)) {
                                        showFloatingMenu = false
                                    }
                                    navigateToOCR = true
                                }
                            )
                            .padding(.trailing, 30)
                        }
                        .padding(.bottom, 8)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // 탭바와 플로팅 버튼을 한 줄에 배치
                    HStack(spacing: 16) {
                        // 탭바
                        CustomTabBar(selectedTab: $selectedTab)
                        
                        // 플로팅 버튼
                        ChatFloatingButton(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showFloatingMenu.toggle()
                            }
                        })
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationDestination(isPresented: $navigateToChat) {
                ChatbotView()
            }
            .navigationDestination(isPresented: $navigateToOCR) {
                OCRCameraView()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}


// MARK: - 커스텀 탭바 컴포넌트
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // 홈
            TabBarButton(
                icon: "house",
                title: "홈",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            // 게시판
            TabBarButton(
                icon: "square.text.square",
                title: "게시판",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            // 프로필
            TabBarButton(
                icon: "folder",
                title: "OCR목록",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.mainws, lineWidth: 1)
                )
        )
    }
}

// MARK: - 일반 탭 버튼
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(isSelected ? .mainws : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 채팅 플로팅 버튼
struct ChatFloatingButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.sub1Ws)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.mainws, lineWidth: 1)
                    )
                
                Image(.chatbotws)
                    .font(.system(size: 28))
            }
        }
    }
}

// MARK: - 플로팅 메뉴
struct FloatingMenuView: View {
    let onChatTapped: () -> Void
    let onOCRTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onChatTapped) {
                Text("대화하기")
                    .font(.pretendard(.medium, size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            Button(action: onOCRTapped) {
                Text("문제분석하기")
                    .font(.pretendard(.medium, size: 18))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
        )
        .frame(width: 220)
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
