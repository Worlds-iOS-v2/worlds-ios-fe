//
//  OCRImageResizingView.swift
//  worlds-fe-v20
//
//  Created by soy on 7/22/25.
//

import SwiftUI

// 이미지 크롭 뷰: 사용자가 이미지를 원하는 영역만큼 잘라낼 수 있는 뷰
struct OCRImageResizingView: View {
    @StateObject var viewModel = OCRViewModel()

    // 원본 이미지
    let originalImage: UIImage
    // 크롭 완료 시 호출되는 콜백
    var onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    // 크롭 영역(0~1 비율)
    @State private var cropRect: CGRect = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
    // 드래그 변화량 누적값
    @State private var dragOffset: CGSize = .zero
    // 현재 드래그 중인 코너
    @State private var activeCorner: Corner? = nil
    // 마지막 드래그 값(누적)
    @State private var lastDragValue: CGSize = .zero
    // 크롭 영역 최소 크기
    let minWidth: CGFloat = 0.1
    let minHeight: CGFloat = 0.1

    // 크롭 사각형의 네 모서리 구분
    enum Corner { case topLeft, topRight, bottomLeft, bottomRight, none }

    var body: some View {
        NavigationStack {
            
            VStack {
                GeometryReader { geo in
                    ZStack {
                        // 원본 이미지 표시
                        Image(uiImage: originalImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        // 크롭 사각형 표시
                        Rectangle()
                            .path(in: cropRectFor(geo: geo))
                            .stroke(.sub1Ws, lineWidth: 2)
                            .background(
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: cropRectFor(geo: geo).width, height: cropRectFor(geo: geo).height)
                                    .position(x: cropRectFor(geo: geo).midX, y: cropRectFor(geo: geo).midY)
                            )
                        // 사각형 전체 이동 제스처
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let dx = (value.translation.width - lastDragValue.width) / geo.size.width
                                        let dy = (value.translation.height - lastDragValue.height) / geo.size.height
                                        lastDragValue = value.translation
                                        var newRect = cropRect
                                        newRect.origin.x = min(max(0, cropRect.origin.x + dx), 1 - cropRect.size.width)
                                        newRect.origin.y = min(max(0, cropRect.origin.y + dy), 1 - cropRect.size.height)
                                        cropRect = newRect
                                    }
                                    .onEnded { _ in
                                        lastDragValue = .zero
                                    }
                            )
                        // 네 모서리(코너) 핸들
                        cornerHandle(.topLeft, geo: geo)
                        cornerHandle(.topRight, geo: geo)
                        cornerHandle(.bottomLeft, geo: geo)
                        cornerHandle(.bottomRight, geo: geo)
                    }
                }
                .aspectRatio(originalImage.size, contentMode: .fit)
                .padding()
                
                Button {
                    if let cropped = cropImage() {
                        onCrop(cropped)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.mainws)
                            .frame(height: 60)
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 4, y: 4)
                        
                        HStack {
                            Image(systemName: "text.viewfinder")
                            Text("OCR 실행")
                        }
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    }
                }
                .padding()
            }
            .navigationTitle("이미지 크롭")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
}


extension OCRImageResizingView {
    // cropRect를 실제 뷰 좌표계로 변환
    private func cropRectFor(geo: GeometryProxy) -> CGRect {
        CGRect(
            x: cropRect.origin.x * geo.size.width,
            y: cropRect.origin.y * geo.size.height,
            width: cropRect.size.width * geo.size.width,
            height: cropRect.size.height * geo.size.height
        )
    }

    // 코너 핸들(모서리 원) 뷰
    @ViewBuilder
    private func cornerHandle(_ corner: Corner, geo: GeometryProxy) -> some View {
        let rect = cropRectFor(geo: geo)
        let size: CGFloat = 24
        let pos: CGPoint = {
            switch corner {
            case .topLeft: return rect.origin
            case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
            case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
            case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
            case .none: return .zero
            }
        }()
        Circle()
            .fill(.mainws)
            .frame(width: size, height: size)
            .position(pos)
            // 코너 드래그 제스처
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let dx = (value.translation.width - lastDragValue.width) / geo.size.width
                        let dy = (value.translation.height - lastDragValue.height) / geo.size.height
                        lastDragValue = value.translation
                        var newRect = cropRect
                        let minDragThreshold: CGFloat = 0.003
                        if abs(dx) < minDragThreshold && abs(dy) < minDragThreshold {
                            return
                        }
                        let isDiagonal = abs(dx) > minDragThreshold && abs(dy) > minDragThreshold
                        switch corner {
                        case .topLeft:
                            if isDiagonal {
                                let delta = abs(dx) > abs(dy) ? dx : dy
                                let newX = max(0, cropRect.origin.x + delta)
                                let newY = max(0, cropRect.origin.y + delta)
                                let maxX = cropRect.origin.x + cropRect.size.width - minWidth
                                let maxY = cropRect.origin.y + cropRect.size.height - minHeight
                                let finalX = min(newX, maxX)
                                let finalY = min(newY, maxY)
                                let appliedDeltaX = finalX - cropRect.origin.x
                                let appliedDeltaY = finalY - cropRect.origin.y
                                let appliedDelta = min(appliedDeltaX, appliedDeltaY)
                                newRect.origin.x += appliedDelta
                                newRect.origin.y += appliedDelta
                                newRect.size.width -= appliedDelta
                                newRect.size.height -= appliedDelta
                            } else {
                                if abs(dx) > minDragThreshold {
                                    let newX = max(0, cropRect.origin.x + dx)
                                    let maxX = cropRect.origin.x + cropRect.size.width - minWidth
                                    let finalX = min(newX, maxX)
                                    let appliedDelta = finalX - cropRect.origin.x
                                    newRect.origin.x += appliedDelta
                                    newRect.size.width -= appliedDelta
                                }
                                if abs(dy) > minDragThreshold {
                                    let newY = max(0, cropRect.origin.y + dy)
                                    let maxY = cropRect.origin.y + cropRect.size.height - minHeight
                                    let finalY = min(newY, maxY)
                                    let appliedDelta = finalY - cropRect.origin.y
                                    newRect.origin.y += appliedDelta
                                    newRect.size.height -= appliedDelta
                                }
                            }
                        case .topRight:
                            if isDiagonal {
                                let delta = abs(dx) > abs(dy) ? -dx : dy
                                let newMaxX = min(1, cropRect.origin.x + cropRect.size.width - delta)
                                let newY = max(0, cropRect.origin.y + delta)
                                let minX = cropRect.origin.x + minWidth
                                let maxY = cropRect.origin.y + cropRect.size.height - minHeight
                                let finalMaxX = max(newMaxX, minX)
                                let finalY = min(newY, maxY)
                                let appliedDeltaX = (cropRect.origin.x + cropRect.size.width) - finalMaxX
                                let appliedDeltaY = cropRect.origin.y - finalY
                                let appliedDelta = min(appliedDeltaX, appliedDeltaY)
                                newRect.size.width -= appliedDelta
                                newRect.origin.y += appliedDelta
                                newRect.size.height -= appliedDelta
                            } else {
                                if abs(dx) > minDragThreshold {
                                    let newMaxX = min(1, cropRect.origin.x + cropRect.size.width - dx)
                                    let minX = cropRect.origin.x + minWidth
                                    let finalMaxX = max(newMaxX, minX)
                                    let appliedDelta = (cropRect.origin.x + cropRect.size.width) - finalMaxX
                                    newRect.size.width -= appliedDelta
                                }
                                if abs(dy) > minDragThreshold {
                                    let newY = max(0, cropRect.origin.y + dy)
                                    let maxY = cropRect.origin.y + cropRect.size.height - minHeight
                                    let finalY = min(newY, maxY)
                                    let appliedDelta = finalY - cropRect.origin.y
                                    newRect.origin.y += appliedDelta
                                    newRect.size.height -= appliedDelta
                                }
                            }
                        case .bottomLeft:
                            if isDiagonal {
                                let delta = abs(dx) > abs(dy) ? dx : -dy
                                let newX = max(0, cropRect.origin.x + delta)
                                let newMaxY = min(1, cropRect.origin.y + cropRect.size.height - delta)
                                let maxX = cropRect.origin.x + cropRect.size.width - minWidth
                                let minY = cropRect.origin.y + minHeight
                                let finalX = min(newX, maxX)
                                let finalMaxY = max(newMaxY, minY)
                                let appliedDeltaX = cropRect.origin.x - finalX
                                let appliedDeltaY = (cropRect.origin.y + cropRect.size.height) - finalMaxY
                                let appliedDelta = min(appliedDeltaX, appliedDeltaY)
                                newRect.origin.x += appliedDelta
                                newRect.size.width -= appliedDelta
                                newRect.size.height -= appliedDelta
                            } else {
                                if abs(dx) > minDragThreshold {
                                    let newX = max(0, cropRect.origin.x + dx)
                                    let maxX = cropRect.origin.x + cropRect.size.width - minWidth
                                    let finalX = min(newX, maxX)
                                    let appliedDelta = finalX - cropRect.origin.x
                                    newRect.origin.x += appliedDelta
                                    newRect.size.width -= appliedDelta
                                }
                                if abs(dy) > minDragThreshold {
                                    let newMaxY = min(1, cropRect.origin.y + cropRect.size.height - dy)
                                    let minY = cropRect.origin.y + minHeight
                                    let finalMaxY = max(newMaxY, minY)
                                    let appliedDelta = (cropRect.origin.y + cropRect.size.height) - finalMaxY
                                    newRect.size.height -= appliedDelta
                                }
                            }
                        case .bottomRight:
                            if isDiagonal {
                                let delta = abs(dx) > abs(dy) ? dx : dy
                                let newMaxX = min(1, cropRect.origin.x + cropRect.size.width + delta)
                                let newMaxY = min(1, cropRect.origin.y + cropRect.size.height + delta)
                                let minX = cropRect.origin.x + minWidth
                                let minY = cropRect.origin.y + minHeight
                                let finalMaxX = max(newMaxX, minX)
                                let finalMaxY = max(newMaxY, minY)
                                let appliedDeltaX = finalMaxX - (cropRect.origin.x + cropRect.size.width)
                                let appliedDeltaY = finalMaxY - (cropRect.origin.y + cropRect.size.height)
                                let appliedDelta = min(appliedDeltaX, appliedDeltaY)
                                newRect.size.width += appliedDelta
                                newRect.size.height += appliedDelta
                            } else {
                                if abs(dx) > minDragThreshold {
                                    let newMaxX = min(1, cropRect.origin.x + cropRect.size.width + dx)
                                    let minX = cropRect.origin.x + minWidth
                                    let finalMaxX = max(newMaxX, minX)
                                    let appliedDelta = finalMaxX - (cropRect.origin.x + cropRect.size.width)
                                    newRect.size.width += appliedDelta
                                }
                                if abs(dy) > minDragThreshold {
                                    let newMaxY = min(1, cropRect.origin.y + cropRect.size.height + dy)
                                    let minY = cropRect.origin.y + minHeight
                                    let finalMaxY = max(newMaxY, minY)
                                    let appliedDelta = finalMaxY - (cropRect.origin.y + cropRect.size.height)
                                    newRect.size.height += appliedDelta
                                }
                            }
                        case .none: break
                        }
                        newRect.size.width = max(newRect.size.width, minWidth)
                        newRect.size.height = max(newRect.size.height, minHeight)
                        newRect.origin.x = min(max(0, newRect.origin.x), 1 - newRect.size.width)
                        newRect.origin.y = min(max(0, newRect.origin.y), 1 - newRect.size.height)
                        cropRect = newRect
                    }
                    .onEnded { _ in
                        activeCorner = nil
                        lastDragValue = .zero
                    }
            )
    }

    // 실제 이미지 크롭
    private func cropImage() -> UIImage? {
        let fixedImage = originalImage.fixedOrientation()
        let imageSize = fixedImage.size
        let crop = CGRect(
            x: cropRect.origin.x * imageSize.width,
            y: cropRect.origin.y * imageSize.height,
            width: cropRect.size.width * imageSize.width,
            height: cropRect.size.height * imageSize.height
        )
        guard let cgImage = fixedImage.cgImage?.cropping(to: crop) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
