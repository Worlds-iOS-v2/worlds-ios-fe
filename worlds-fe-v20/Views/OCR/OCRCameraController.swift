//
//  OCRCameraController.swift
//  worlds-fe-v20
//
//  Created by soy on 7/22/25.
//

import Foundation
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

// 카메라 촬영 결과를 전달하는 델리게이트 프로토콜
protocol OCRCameraControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage?)
}

// 카메라 촬영 및 미리보기, 사진 캡처를 담당하는 UIViewController
class OCRCameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: OCRCameraControllerDelegate?
    private let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var currentInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    var cameraPosition: AVCaptureDevice.Position = .back
    
    private var initialZoom: CGFloat = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundws
        setupPreviewLayer()
        configureCaptureSession(position: cameraPosition)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // 미리보기 레이어 설정
    private func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }

    // 카메라 권한 요청
    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.captureSession.startRunning()
                    }
                }
            }
        case .authorized:
            // 백그라운드에서 세션 시작
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        case .denied, .restricted:
            print("카메라 권한이 거부되었습니다.")
        @unknown default:
            print("알 수 없는 권한 상태입니다.")
        }
    }

    // 캡처 세션 구성 및 카메라 전환
    func configureCaptureSession(position: AVCaptureDevice.Position) {
        cameraPosition = position
        captureSession.stopRunning() // beginConfiguration() 전에 중지
        captureSession.beginConfiguration()
        // 기존 입력 제거
        if let currentInput = currentInput {
            captureSession.removeInput(currentInput)
        }
        // 새 입력 추가
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        guard let cameraDevice = discoverySession.devices.first else {
            print("사용 가능한 카메라가 없습니다.")
            captureSession.commitConfiguration()
            return
        }
        do {
            let deviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
                currentInput = deviceInput
            }
        } catch {
            print("카메라 설정 오류: \(error.localizedDescription)")
        }
        // 기존 출력 제거 및 새 출력 추가
        if let photoOutput = photoOutput {
            captureSession.removeOutput(photoOutput)
        }
        let newPhotoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(newPhotoOutput) {
            captureSession.addOutput(newPhotoOutput)
            photoOutput = newPhotoOutput
        }
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    // 카메라 전환
    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = (cameraPosition == .back) ? .front : .back
        configureCaptureSession(position: newPosition)
    }

    // 사진 촬영
    func capturePhoto() {
        guard let photoOutput = photoOutput, captureSession.isRunning else {
            print("photoOutput이 nil이거나 세션이 실행 중이 아님")
            return
        }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - AVCapturePhotoCaptureDelegate
    // 사진 촬영 결과 콜백
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("사진 촬영 오류: \(error)")
            delegate?.didCapturePhoto(nil)
            return
        }
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            print("이미지 데이터 변환 실패")
            delegate?.didCapturePhoto(nil)
            return
        }
        print("이미지 생성 성공: \(image.size)")
        delegate?.didCapturePhoto(image)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let device = currentInput?.device else { return }
        
        if gesture.state == .began {
            initialZoom = device.videoZoomFactor
        }
        
        var zoomFactor = initialZoom * gesture.scale
        zoomFactor = max(1.0, min(device.activeFormat.videoMaxZoomFactor, zoomFactor))
        
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch {
            print("줌 설정 실패: \(error)")
        }
    }
}

// SwiftUI에서 카메라 컨트롤러를 사용할 수 있게 하는 래퍼
struct CameraPreview: UIViewControllerRepresentable {
    @Binding var cameraPosition: AVCaptureDevice.Position
    @Binding var cameraController: OCRCameraController?
    var onPhotoCaptured: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> OCRCameraController {
        let controller = OCRCameraController()
        controller.delegate = context.coordinator
        controller.configureCaptureSession(position: cameraPosition)
        cameraController = controller
        return controller
    }
    
    func updateUIViewController(_ uiViewController: OCRCameraController, context: Context) {
        // 카메라 전환
        if uiViewController.cameraPosition != cameraPosition {
            uiViewController.configureCaptureSession(position: cameraPosition)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator: 델리게이트 콜백을 SwiftUI로 전달
    class Coordinator: NSObject, OCRCameraControllerDelegate {
        let parent: CameraPreview
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        func didCapturePhoto(_ image: UIImage?) {
            parent.onPhotoCaptured(image)
        }
    }
    
    // 카메라 권한 요청
    func requestCameraPermission(_ controller: OCRCameraController) {
        controller.requestCameraPermission()
    }
    // 사진 촬영
    func capturePhoto(_ controller: OCRCameraController) {
        controller.capturePhoto()
    }
}

// 앨범 선택을 위한 ImagePicker
struct ImagePreview: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1  // OCR용 단일 이미지
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePreview
        
        init(_ parent: ImagePreview) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                // 사용자가 취소한 경우
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("이미지 로딩 에러: \(error)")
                            return
                        }
                        self?.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}
