//
//  QRCodeScannerView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/7/25.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRCodeScannerView
        var session: AVCaptureSession?
        private var isHandling = false

        init(parent: QRCodeScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let code = metadataObject.stringValue {
                guard !isHandling else { return }
                isHandling = true
                // 세션 중지는 백그라운드 스레드에서
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.session?.stopRunning()
                }
                // 콜백은 메인 스레드에서
                DispatchQueue.main.async { [weak self] in
                    self?.parent.foundCode(code.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }

    var foundCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return controller }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
            context.coordinator.session = session
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = controller.view.bounds
        previewLayer.masksToBounds = true
        controller.view.layer.addSublayer(previewLayer)
        previewLayer.frame = controller.view.layer.bounds

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
