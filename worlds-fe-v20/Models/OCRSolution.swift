//
//  OCRSolution.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/30/25.
//

import Foundation

struct OCRSolution: Codable {
    let message: String
    let statusCode: Int
    let keyConcept: String
    let solution: String
    let summary: String
}
