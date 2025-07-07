//
//  Date+Extension.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/7/25.
//

import Foundation

extension Date {
    func toString(format: String = "yyyy년 MM월 dd일" ) -> String {
        let formatters = DateFormatter()
        formatters.dateFormat = format
        return formatters.string(from: self)
    }
}
