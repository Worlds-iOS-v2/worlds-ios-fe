//
//  Font+Extension.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/20/25.
//

import SwiftUI

extension Font {
    enum BMJua: String {
        case regular = "BMJUAOTF"
    }
    
    static func bmjua(_ weight: BMJua, size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}
