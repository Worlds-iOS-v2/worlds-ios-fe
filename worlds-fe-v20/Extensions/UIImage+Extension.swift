//
//  UIImage+Extension.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/28/25.
//

import UIKit

extension UIImage: Identifiable {
    public var id: UUID { UUID() }
}

// UIImage의 방향을 보정하는 확장
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
