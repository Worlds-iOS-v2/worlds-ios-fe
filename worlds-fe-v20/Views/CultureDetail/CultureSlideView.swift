//
//  CultureSlideView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/8/25.
//

import SwiftUI

protocol CultureDisplayable {
    var title: String { get }
    var applicationPeriod: String { get }
    var programPeriod: String { get }
    var borough: String { get }
    var url: String { get }
}

struct CultureSlideView<T: CultureDisplayable>: View {
    let datas: [T]
    let isLoading: Bool
    /// 현재 인덱스 저장
    @State private var currentIndex = 0
    
    var textColor: Color = .mainfontws

    // MARK: - body
    var body: some View {
        VStack {
            // MARK: - Image Slide
            if datas.isEmpty || isLoading {
                // 데이터가 없거나 로딩 중일 때 로딩 상태 표시
                Link(destination: URL(string: "https://www.notion.so/World-Study-_2-0-0-1fc800c9877b80d6a86ce296013ec7d7?source=copy_link")!) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(isLoading ? "로딩 중..." : "데이터 없음")
                                .font(.pretendard(.regular, size: 20))
                                .foregroundColor(textColor)

                            Spacer()

                            Text("")
                                .font(.pretendard(.regular, size: 14))
                                .foregroundColor(textColor)
                        }
                        .padding(.bottom, 12)

                        Text("신청 기간: \(isLoading ? "로딩 중..." : "데이터 없음")")
                            .font(.pretendard(.regular, size: 14))
                            .foregroundColor(textColor)
                            .padding(.bottom, 4)

                        Text("활동 기간: \(isLoading ? "로딩 중..." : "데이터 없음")")
                            .font(.pretendard(.regular, size: 14))
                            .foregroundColor(textColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    Rectangle()
                        .fill(Color.white)
                }
                .ignoresSafeArea()
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
            } else {
                InfinitePageBaseView(
                    selection: $currentIndex,
                    before: { $0 == 0 ? datas.count - 1 : $0 - 1 },
                    after: { $0 == datas.count - 1 ? 0 : $0 + 1 },
                    view: { index in
                        Link(destination: URL(string: datas[index].url)!) {
                            VStack(alignment: .leading) {
                                Text(datas[index].borough)
                                    .font(.pretendard(.bold, size: 16))
                                    .foregroundColor(.subfontws)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 8)
                                
                                Text(datas[index].title)
                                    .font(.pretendard(.semiBold, size: 20))
                                    .foregroundColor(textColor)
                                    .lineLimit(1)
                                    .padding(.bottom, 8)
                                
                                
                                Text("신청 기간: \(datas[index].applicationPeriod)")
                                    .font(.pretendard(.medium, size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 4)
                                
                                Text("활동 기간: \(datas[index].programPeriod)")
                                    .font(.pretendard(.medium, size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background {
                            Rectangle()
                                .fill(Color.white)
                                .tag(index)
                        }
                        .ignoresSafeArea()
                        .cornerRadius(12)
                    }
                )
                // 인덱스 변화
                .onChange(of: currentIndex) { newIndex in  // iOS 16 방식
                    currentIndex = newIndex
                }
                .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
            }

            // 인디케이터
            imageCustomIndicator()
        }
    }
}

extension CultureSlideView {
    // MARK: - Slides
    /// 다음 아이템으로 이동 (수동 전용)
    private func moveToNextIndex() {
        guard !datas.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % datas.count
        withAnimation {
            currentIndex = nextIndex
        }
    }

    // MARK: - Indicator
    /// 이미지 커스텀 인디케이터
    private func imageCustomIndicator() -> some View {
        ZStack {
            if datas.count > 1 {
                HStack(spacing: 6) {
                    ForEach(datas.indices, id: \.self) { index in
                        Capsule()
                            .fill(currentIndex == index ? Color.mainws : Color.mainfontws)
                            .frame(width: currentIndex == index ? 16 : 6, height: 6)
                            .overlay(
                                Capsule()
                                    .stroke(Color.sub1Ws, lineWidth: 1)
                            )
                            .opacity(currentIndex == index ? 1 : 0.5)
                    }
                }  // H
                .padding(.bottom, 24)
            }  // if
        }  // Z
    }
}
