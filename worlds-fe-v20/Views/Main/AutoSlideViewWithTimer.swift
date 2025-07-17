//
//  TimerSlides.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI

struct AutoSlideViewWithTimer: View {
    // MARK: - properties
    /// 무한으로 순환할 배열
    var colors: [Color] = [.red, .orange, .yellow, .blue, .green]
    /// 애니메이션 타이머
    @State private var timer: Timer?
    /// 현재 인덱스 저장
    @State private var currentIndex = 0
    
    // MARK: - body
    var body: some View {
        
        VStack {
            // MARK: - Image Slide
            InfinitePageBaseView(
                selection: $currentIndex,
                before: { $0 == 0 ? colors.count - 1 : $0 - 1 },
                after: { $0 == colors.count - 1 ? 0 : $0 + 1 },
                view: { index in
                    ZStack {
                        Rectangle()
                            .fill(colors[index])
                            .tag(index)
                    } // Z
                    .ignoresSafeArea()
                })
            // 인덱스 변화
            .onChange(of: currentIndex) { newIndex in  // iOS 16 방식
                currentIndex = newIndex
                startTimer()
            }
            
            // MARK: - 액션
            // 수동 드래그 시 타이머 조정 액션
            .gesture(manageTimerWithIndex())
            
            // MARK: - LifeCycle (타이머 작동 관리)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .cornerRadius(16)
            
            
            // 인디케이터
            imageCustomIndicator()
        }
    }
}

extension AutoSlideViewWithTimer {
    // MARK: - Slides
    /// 다음 아이템으로 이동
    private func moveToNextIndex() {
        let nextIndex = (currentIndex + 1) % colors.count
        withAnimation() {
            currentIndex = nextIndex
        }
    }
    
    // MARK: - Timer
    /// 타이머 작동 (시작)
    private func startTimer() {
        /// 기존 타이머가 있으면 중지
        stopTimer()
        /// 3초마다 반복되는 타이머 설정
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            moveToNextIndex()
        }
    }
    
    /// 타이머 작동 멈춤
    private func stopTimer() {
        /// 타이머 무효화 + nil로 설정
        timer?.invalidate()
        timer = nil
    }
    /// 사용자가 수동으로 슬라이드 넘기려고 할 때 DragGesture
    /// - 인덱스가 바뀌지 않으면 타이머가 계속 가동
    /// - 인덱스가 바뀌면 타이머가 멈추고 다시 가동
    private func manageTimerWithIndex() -> some Gesture {
        /// 커스텀 제스처
        var userDragGesture: some Gesture {
            /// gaurd 조건: 드래그 동작 중 인덱스가 변경되었는지 확인
            guard currentIndex == currentIndex else {
                /// 인덱스가 바뀌면 타이머 멈춤 O
                return DragGesture(coordinateSpace: .global)
                    .onChanged { _ in
                        stopTimer()
                    }
            } // guard
            
            /// 인덱스가 바뀌지 않으면 타이머 멈춤 X
            return DragGesture(coordinateSpace: .global)
                .onChanged { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startTimer()
                    }
                }
        }
        /// 커스텀한 제스처 반환
        return userDragGesture
    }
    
    // MARK: - Indicator
    /// 이미지 커스텀 인디케이터
    private func imageCustomIndicator() -> some View {
        ZStack {
            if colors.count > 1 {
                HStack(spacing: 4) {
                    ForEach(colors.indices, id: \.self) { index in
                        Capsule()
                            .stroke(.white, lineWidth: 1)
                            .frame(width: currentIndex == index ? 16 : 6, height: 6)
                            .opacity(currentIndex == index ? 1 : 0.5)
                            .background(currentIndex == index ? .white : Color.clear)
                    }
                } // H
                .padding(.bottom, 24)
            } // if
        } // Z
    }
    
}


#Preview {
    AutoSlideViewWithTimer()
}
