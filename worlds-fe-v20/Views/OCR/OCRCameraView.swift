//
//  OCRCameraView.swift
//  worlds-fe-v20
//
//  Created by soy on 7/22/25.
//

import SwiftUI
import AVFoundation
import UIKit

// OCR 카메라 뷰: 카메라 미리보기, 촬영, 사진 선택, 크롭, 결과 뷰까지 전체 흐름을 담당
struct OCRCameraView: View {
    // 카메라 방향(전/후면)
    @State private var cameraPosition: AVCaptureDevice.Position = .back
    // 사진 라이브러리 표시 여부
    @State private var showingPhotoLibrary = false
    // 선택된 원본 이미지
    @State private var selectedImage: UIImage? = nil
    // 크롭된 이미지
    @State private var croppedImage: UIImage? = nil
    // 결과 뷰 표시 여부
    @State private var showingResultView = false
    // 카메라 컨트롤러 인스턴스
    @State private var cameraController = OCRCameraController()
    // 공유 OCRViewModel 인스턴스
    @StateObject private var ocrViewModel = OCRViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            CameraPreview(
                cameraPosition: $cameraPosition,
                cameraController: $cameraController,
                onPhotoCaptured: { image in
                    print("onPhotoCaptured 호출, image: \(String(describing: image))")
                    DispatchQueue.main.async {
                        selectedImage = image
                    }
                }
            )
            .cornerRadius(32)
            .padding(.horizontal)
            .padding(.top, 10)
            
            VStack {
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button {
                        showingPhotoLibrary = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.mainws)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 사진 촬영 버튼
                    Button {
                        print("촬영 버튼 클릭됨")
                        cameraController.capturePhoto()
                    } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(.mainws, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                            )
                    }
                    
                    Spacer()
                    
                    // 카메라 전환 버튼
                    Button {
                        cameraPosition = (cameraPosition == .back) ? .front : .back
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.mainws)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle("OCR")
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
        }
        // 사진 라이브러리에서 이미지 선택 시 표시되는 시트
        .sheet(isPresented: $showingPhotoLibrary) {
            ImagePreview(selectedImage: $selectedImage)
        }
        // 이미지 선택 시 크롭 뷰로 네비게이션
        .navigationDestination(isPresented: Binding(
            get: { selectedImage != nil },
            set: { if !$0 { selectedImage = nil } }
        )) {
            if let image = selectedImage {
                OCRImageResizingView(originalImage: image) { cropped in
                    croppedImage = cropped
                    selectedImage = nil
                    showingResultView = true
                    // 새로운 OCR 세션 시작 시 Summary 데이터 초기화
                    ocrViewModel.resetSummaryData()
                }
            }
        }
        // 크롭된 이미지 결과 뷰로 네비게이션
        .navigationDestination(isPresented: $showingResultView) {
            if let image = croppedImage {
                OCRResultView(selectedImage: image)
                    .environmentObject(ocrViewModel)
            }
        }
        // 뷰가 나타날 때 카메라 권한 요청
        .onAppear {
            cameraController.requestCameraPermission()
        }
    }
}
