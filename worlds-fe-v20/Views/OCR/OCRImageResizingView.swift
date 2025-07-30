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
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // 원본 이미지
    let originalImage: UIImage
    // 크롭 완료 시 호출되는 콜백
    var onCrop: (UIImage) -> Void
    // 크롭 영역(0~1 비율) - 전체 이미지 영역으로 초기화
    @State private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
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
        VStack {
            GeometryReader { geo in
                ZStack {
                    // 원본 이미지 표시
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .cornerRadius(32)
                    
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.mainws)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    appState.flow = .main
                } label: {
                    Image(systemName: "house")
                        .foregroundColor(.mainws)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
    }
}


extension OCRImageResizingView {
    // cropRect를 실제 뷰 좌표계로 변환
    private func cropRectFor(geo: GeometryProxy) -> CGRect {
        let imageSize = geo.size
        let imageAspectRatio = originalImage.size.width / originalImage.size.height
        let viewAspectRatio = imageSize.width / imageSize.height
        
        var actualImageSize: CGSize
        var imageOffset: CGPoint
        
        if imageAspectRatio > viewAspectRatio {
            // 이미지가 뷰보다 가로가 길 때
            actualImageSize = CGSize(width: imageSize.width, height: imageSize.width / imageAspectRatio)
            imageOffset = CGPoint(x: 0, y: (imageSize.height - actualImageSize.height) / 2)
        } else {
            // 이미지가 뷰보다 세로가 길 때
            actualImageSize = CGSize(width: imageSize.height * imageAspectRatio, height: imageSize.height)
            imageOffset = CGPoint(x: (imageSize.width - actualImageSize.width) / 2, y: 0)
        }
        
        return CGRect(
            x: imageOffset.x + cropRect.origin.x * actualImageSize.width,
            y: imageOffset.y + cropRect.origin.y * actualImageSize.height,
            width: cropRect.size.width * actualImageSize.width,
            height: cropRect.size.height * actualImageSize.height
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
                        
                        // 경계 체크를 위한 최대값 계산
                        let maxX = 1.0 - minWidth
                        let maxY = 1.0 - minHeight
                        
                        switch corner {
                        case .topLeft:
                            let newX = max(0, min(cropRect.origin.x + dx, cropRect.origin.x + cropRect.size.width - minWidth))
                            let newY = max(0, min(cropRect.origin.y + dy, cropRect.origin.y + cropRect.size.height - minHeight))
                            let deltaX = newX - cropRect.origin.x
                            let deltaY = newY - cropRect.origin.y
                            newRect.origin.x = newX
                            newRect.origin.y = newY
                            newRect.size.width = max(minWidth, cropRect.size.width - deltaX)
                            newRect.size.height = max(minHeight, cropRect.size.height - deltaY)
                            
                        case .topRight:
                            let newMaxX = min(1.0, max(cropRect.origin.x + minWidth, cropRect.origin.x + cropRect.size.width + dx))
                            let newY = max(0, min(cropRect.origin.y + dy, cropRect.origin.y + cropRect.size.height - minHeight))
                            let deltaX = newMaxX - (cropRect.origin.x + cropRect.size.width)
                            let deltaY = newY - cropRect.origin.y
                            newRect.size.width = max(minWidth, cropRect.size.width + deltaX)
                            newRect.origin.y = newY
                            newRect.size.height = max(minHeight, cropRect.size.height - deltaY)
                            
                        case .bottomLeft:
                            let newX = max(0, min(cropRect.origin.x + dx, cropRect.origin.x + cropRect.size.width - minWidth))
                            let newMaxY = min(1.0, max(cropRect.origin.y + minHeight, cropRect.origin.y + cropRect.size.height + dy))
                            let deltaX = newX - cropRect.origin.x
                            let deltaY = newMaxY - (cropRect.origin.y + cropRect.size.height)
                            newRect.origin.x = newX
                            newRect.size.width = max(minWidth, cropRect.size.width - deltaX)
                            newRect.size.height = max(minHeight, cropRect.size.height + deltaY)
                            
                        case .bottomRight:
                            let newMaxX = min(1.0, max(cropRect.origin.x + minWidth, cropRect.origin.x + cropRect.size.width + dx))
                            let newMaxY = min(1.0, max(cropRect.origin.y + minHeight, cropRect.origin.y + cropRect.size.height + dy))
                            let deltaX = newMaxX - (cropRect.origin.x + cropRect.size.width)
                            let deltaY = newMaxY - (cropRect.origin.y + cropRect.size.height)
                            newRect.size.width = max(minWidth, cropRect.size.width + deltaX)
                            newRect.size.height = max(minHeight, cropRect.size.height + deltaY)
                            
                        case .none: break
                        }
                        
                        // 최종 경계 체크
                        newRect.origin.x = max(0, min(newRect.origin.x, maxX))
                        newRect.origin.y = max(0, min(newRect.origin.y, maxY))
                        newRect.size.width = max(minWidth, min(newRect.size.width, 1 - newRect.origin.x))
                        newRect.size.height = max(minHeight, min(newRect.size.height, 1 - newRect.origin.y))
                        
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
