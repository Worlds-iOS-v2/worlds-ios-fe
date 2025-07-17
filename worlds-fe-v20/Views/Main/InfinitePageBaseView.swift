//
//  InfinitePageView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

struct InfinitePageBaseView<C, T>: View where C: View, T: Hashable {
    @Binding var selection: T
    
    // 이전 항목을 계산함
    let before: (T) -> T
    // 다음 항목을 계산함
    let after: (T) -> T
    
    // 뷰 생성
    @ViewBuilder let view: (T) -> C
    
    // 현재 탭 인덱스 저장
    @State private var currentTab: Int = 0
    
    var body: some View {
        
        // 이전 및 다음 아이템 계산
        let previousIndex = before(selection)
        let nextIndex = after(selection)
        
        if #available(iOS 17.0, *) {
            TabView(selection: $currentTab) {
                
                // 이전 항목 표시 뷰
                view(previousIndex)
                    .tag(-1)
                
                // 현재 뷰
                view(selection)
                    .onDisappear() {
                        if currentTab != 0 {
                            selection = currentTab < 0 ? previousIndex : nextIndex
                            currentTab = 0
                        }
                    }
                    .tag(0)
                
                // 다음 항목을 표시하는 뷰
                view(nextIndex)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selection) { newValue in  // iOS 16 방식
                selection = newValue
            }
            
            // FIXME: workaround to avoid glitch when swiping twice very quickly
            // 탭이 0이 아닐 때 스와이프를 비활성화하여 빠른 스와이프 시 발생하는 글리치 방지
            .disabled(currentTab != 0)
        } else {
            // Fallback on earlier versions
        }
        
    }
}

//#Preview {
//    InfinitePageView()
//}
