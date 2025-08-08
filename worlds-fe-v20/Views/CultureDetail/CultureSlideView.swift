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
    var location: String { get }
}

struct CultureSlideView<T: CultureDisplayable>: View {
    let datas: [T]
    /// 현재 인덱스 저장
    @State private var currentIndex = 0

    // MARK: - body
    var body: some View {
        VStack {
            // MARK: - Image Slide
            InfinitePageBaseView(
                selection: $currentIndex,
                before: { $0 == 0 ? datas.count - 1 : $0 - 1 },
                after: { $0 == datas.count - 1 ? 0 : $0 + 1 },
                view: { index in
                    Link(destination: URL(string: "https://www.notion.so/World-Study-_2-0-0-1fc800c9877b80d6a86ce296013ec7d7?source=copy_link")!) {
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background {
                        Rectangle()
                            .fill(Color.backgroundws)
                            .tag(index)
                    }
                    .ignoresSafeArea()
                    .cornerRadius(16)
                }
            )
            // 인덱스 변화
            .onChange(of: currentIndex) { newIndex in  // iOS 16 방식
                currentIndex = newIndex
            }
            .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)

            // 인디케이터
            imageCustomIndicator()
        }
    }
}

extension CultureSlideView {
    // MARK: - Slides
    /// 다음 아이템으로 이동 (수동 전용)
    private func moveToNextIndex() {
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
                HStack(spacing: 4) {
                    ForEach(datas.indices, id: \.self) { index in
                        Capsule()
                            .stroke(.sub1Ws, lineWidth: 1)
                            .frame(
                                width: currentIndex == index ? 16 : 6, height: 6
                            )
                            .opacity(currentIndex == index ? 1 : 0.5)
                            .background(
                                currentIndex == index ? .sub1Ws : .backgroundws)
                    }
                }  // H
                .padding(.bottom, 24)
            }  // if
        }  // Z
    }

}
