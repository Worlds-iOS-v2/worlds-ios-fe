//
//  MenteeTranslation.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/4/25.
//

struct MenteeTranslation: Codable, Hashable {
    let id: Int
    let menteeId: Int
    let originalText: [String]
    let translatedText: [String]
    let createdAt: String
    let keyConcept: String
    let solution: String
    let summary: String
}
