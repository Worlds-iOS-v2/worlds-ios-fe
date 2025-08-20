//
//  SupportedLanguage.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/20/25.
//

import SwiftUI

enum SupportedLanguage: String, CaseIterable {
    case korean = "ko"
    case english = "en"
    case vietnamese = "vi"
    case japanese = "ja"
    case chinese = "zh"
    case thai = "th"
    case russian = "ru"
    
    var displayName: String {
        switch self {
        case .korean:
            return "한국어"
        case .english:
            return "영어"
        case .vietnamese:
            return "베트남어"
        case .chinese:
            return "중국어"
        case .thai:
            return "태국어"
        case .russian:
            return "러시아어"
        default:
            return "영어"
        }
    }
    
    static func getCurrentLanguage() -> SupportedLanguage {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let languageCode = preferredLanguage.components(separatedBy: "-").first ?? "en"
        
        return SupportedLanguage(rawValue: languageCode.lowercased()) ?? .english
    }
    
    static func getCurrentLanguageCode() -> String {
        return getCurrentLanguage().rawValue
    }
    
    static func getCurrentLanguageName() -> String {
        return getCurrentLanguage().displayName
    }
}
