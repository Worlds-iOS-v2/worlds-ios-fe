//
//  ChatbotViewModel.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

import Foundation

final class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatbotMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let chatbotService = ChatbotAPIManager.shared
    
    init() {
        // 초기 환영 메시지
        addWelcomeMessage()
    }
    
    // 환영 메시지
    private func addWelcomeMessage() {
        let welcomeMessage = ChatbotMessage(
            content: "안녕하세요! 무엇을 도와드릴까요?",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
    
    @MainActor
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatbotMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        // 로딩
        isLoading = true
        errorMessage = nil
        
        do {
            let answer = try await chatbotService.sendQuestion(question: text)
            
            let botMessage = ChatbotMessage(content: answer, isUser: false)
            messages.append(botMessage)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "답변을 받는데 실패했어요. 다시 시도해주세요."
            
            let errorBotMessage = ChatbotMessage(
                content: "죄송해요, 답변을 가져오는데 문제가 발생했어요. 😢\n잠시 후 다시 시도해주세요.",
                isUser: false
            )
            messages.append(errorBotMessage)
            
            print("❌ Chatbot error: \(error.localizedDescription)")
        }
    }
    
    // 메세지 초기화
    func clearMessages() {
        messages.removeAll()
        addWelcomeMessage()
    }
}
