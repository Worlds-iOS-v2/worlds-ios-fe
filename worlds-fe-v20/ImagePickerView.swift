//
//  ImagePickerView.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/8/25.
//

import SwiftUI
import UIKit

struct ImagePickerView: UIViewControllerRepresentable {
    // **  1. 바인딩 변수 (선택한 이미지 전달)
    @Binding var selectedImage: UIImage?
    
    // **  2. 사진첩 or 카메라
    var sourceType: UIImagePickerController.SourceType
    
    // 3. 뷰 닫기용 환경변수
    @Environment(\.presentationMode) var presentationMode
    
    // 4. Coordinator 생성
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // 5. **  UIKit 뷰컨트롤러 생성
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    // 6. 업데이트 필요 없음
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    // **  7. 델리게이트 처리(SwiftUI로 사진 전송)
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
