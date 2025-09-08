//
//  String+Localization.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 9/8/25.
//

import SwiftUI

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
