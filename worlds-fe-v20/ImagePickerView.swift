//
//  ImagePickerView.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/8/25.
//

import SwiftUI
import UIKit
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    // **  1. 이미지 배열로 변경
    @Binding var selectedImages: [UIImage]
    
    // **  2. 사진첩 or 카메라
//    var sourceType: UIImagePickerController.SourceType
    
    // 3. 뷰 닫기용 환경변수
    @Environment(\.presentationMode) var presentationMode
    
    // 4. Coordinator 생성
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // 5. **  UIKit 뷰컨트롤러 생성
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 3
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    // 6. 업데이트 필요 없음
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    // **  7. 델리게이트 처리(SwiftUI로 사진 전송)
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
            var parent: ImagePickerView

            init(_ parent: ImagePickerView) {
                self.parent = parent
            }

            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                parent.selectedImages = []

                let group = DispatchGroup()

                for result in results {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        defer { group.leave() }
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }

                group.notify(queue: .main) {
                    picker.dismiss(animated: true)
                }
            }
        }
    }
