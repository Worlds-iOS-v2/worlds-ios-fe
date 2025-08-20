//
//  OCRListResponse.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/19/25.
//

struct OCRList: Codable, Identifiable {
    let id: Int
    let originalText: [String]
    let translatedText: [String]
    let createdAt: String
    let keyConcept: String
    let solution: String
    let summary: String
}
