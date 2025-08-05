//
//  TabbarView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/31/25.
//

import SwiftUI

struct TabbarView: View {
    var body: some View {
        NavigationStack {
            TabView {
                MainView(viewModel: MainViewModel())
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                
                QuestionView(viewModel: QuestionViewModel())
                    .tabItem {
                        Image(systemName: "questionmark.circle")
                        Text("Question")
                    }
                
                OCRCameraView()
                    .tabItem {
                        Image(systemName: "camera")
                        Text("OCR")
                    }
                
                // 채팅
                //ChatView()
//                    .tabItem {
//                        Image(systemName: "message")
//                        Text("Chat")
//                    }
                
                // 마이페이지
                MyPageView()
                    .tabItem {
                        Image(systemName: "person")
                        Text("MyPage")
                    }
            }
        }
    }
}

#Preview {
    TabbarView()
}
