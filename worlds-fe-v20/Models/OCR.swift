//
//  OCR.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/30/25.
//

import Foundation

struct OCR: Codable {
    let message: String
    let statusCode: Int
    let originalText: [String]
    let translatedText: [String]
}
