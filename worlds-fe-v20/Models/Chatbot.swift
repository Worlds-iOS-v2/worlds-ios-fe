//
//  Chatbot.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

import Foundation

struct ChatbotMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: String = UUID().uuidString, content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct ChatbotRequest: Codable {
    let question: String
}

struct ChatbotResponse: Codable {
    let message: String
    let statusCode: Int
    let answer: String
}
