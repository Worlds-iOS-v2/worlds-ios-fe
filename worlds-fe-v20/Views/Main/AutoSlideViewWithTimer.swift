//
//  TimerSlides.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/15/25.
//

import SwiftUI
import Kingfisher

struct AutoSlideViewWithTimer: View {
    // MARK: - properties
    /// 무한으로 순환할 배열
    let datas: [EventProgram]
    let isLoading: Bool

    /// 애니메이션 타이머
    @State private var timer: Timer?
    /// 현재 인덱스 저장
    @State private var currentIndex = 0
    
    // MARK: - body
    var body: some View {
        
        VStack {
            // MARK: - Image Slide
            if datas.isEmpty || isLoading {
                // 데이터가 없거나 로딩 중일 때 로딩 상태 표시
                VStack {
                    Rectangle()
                        .fill(.backgroundws)
                        .frame(height: 200)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(isLoading ? "로딩 중..." : "데이터 없음")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Text("")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        .padding(.bottom, 12)
                        
                        Text("신청 기간: \(isLoading ? "로딩 중..." : "데이터 없음")")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 4)
                        
                        Text("활동 기간: \(isLoading ? "로딩 중..." : "데이터 없음")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background{
                        Rectangle()
                            .fill(Color.backgroundws)
                    }
                }
                .ignoresSafeArea()
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
            } else {
                InfinitePageBaseView(
                    selection: $currentIndex,
                    before: { $0 == 0 ? datas.count - 1 : $0 - 1 },
                    after: { $0 == datas.count - 1 ? 0 : $0 + 1 },
                    view: { index in
                        ZStack {
                            VStack(spacing: 0) {
                                KFImage(URL(string: datas[index].image))
                                    .placeholder {
                                        // 로딩 중
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                            )
                                    }
                                    .onFailure { error in
                                        print("이미지 로드 실패: \(error)")
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .overlay(
                                        // 이미지 로드 실패 시 오버레이
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .overlay(
                                                VStack(spacing: 8) {
                                                    Image(systemName: "photo")
                                                        .font(.title2)
                                                        .foregroundColor(.gray)
                                                    
                                                    Text("이미지 없음")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            )
                                            .opacity(0) // Kingfisher가 실패 시 자동으로 처리
                                    )
                                
                                Link(destination: URL(string: datas[index].url)!) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(datas[index].title)
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            
                                            Spacer()
                                            
                                            Text(datas[index].location)
                                                .font(.caption)
                                                .foregroundColor(.black)
                                        }
                                        .padding(.bottom, 12)
                                        
                                        Text("신청 기간: \(datas[index].applicationPeriod)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 4)
                                        
                                        Text("활동 기간: \(datas[index].programPeriod)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background{
                                        Rectangle()
                                            .fill(Color.backgroundws)
                                    }
                                }
                            }
                        }
                        .ignoresSafeArea()
                        .cornerRadius(16)
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
                .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
            }
            
            // 인디케이터
            imageCustomIndicator()
        }
    }
}

extension AutoSlideViewWithTimer {
    // MARK: - Slides
    /// 다음 아이템으로 이동
    private func moveToNextIndex() {
        guard !datas.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % datas.count
        withAnimation() {
            currentIndex = nextIndex
        }
    }
    
    // MARK: - Timer
    /// 타이머 작동 (시작)
    private func startTimer() {
        /// 기존 타이머가 있으면 중지
        stopTimer()
        /// 데이터가 없으면 타이머 시작하지 않음
        guard !datas.isEmpty else { return }
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
            if datas.count > 1 {
                HStack(spacing: 4) {
                    ForEach(datas.indices, id: \.self) { index in
                        Capsule()
                            .stroke(.sub1Ws, lineWidth: 1)
                            .frame(width: currentIndex == index ? 16 : 6, height: 6)
                            .opacity(currentIndex == index ? 1 : 0.5)
                            .background(currentIndex == index ? .sub1Ws : .backgroundws)
                    }
                } // H
                .padding(.bottom, 24)
            } // if
        } // Z
    }
    
}


//#Preview {
//    AutoSlideViewWithTimer()
//}
