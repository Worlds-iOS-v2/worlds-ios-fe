//
//  APIErrorResponse.swift
//  worlds-fe-v20
//
//  Created by soy on 7/21/25.
//

struct APIErrorResponse: Codable {
    let message: [String]
    let error: String
    let statusCode: Int
}
