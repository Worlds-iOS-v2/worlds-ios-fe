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
    
    enum PretendardVariable: String {
        case thin = "PretendardVariable-Thin"
        case extraLight = "PretendardVariable-ExtraLight"
        case light = "PretendardVariable-Light"
        case regular = "PretendardVariable-Regular"
        case medium = "PretendardVariable-Medium"
        case semiBold = "PretendardVariable-SemiBold"
        case bold = "PretendardVariable-Bold"
        case extraBold = "PretendardVariable-ExtraBold"
        case black = "PretendardVariable-Black"
    }

    static func bmjua(_ weight: BMJua, size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
    
    static func pretendard(_ weight: PretendardVariable, size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}
