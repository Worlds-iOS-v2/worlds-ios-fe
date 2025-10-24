//
//  ChatbotView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

import SwiftUI

struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 헤더
                headerView
                
                // 메시지 리스트
                messageListView
                
                // 입력창
                inputView
            }
        }
        .background(.background2Ws)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.mainws)
                    .font(.system(size: 24, weight: .regular))
            }
            
            Spacer()
            
            Text("AI 대화")
                .font(.pretendard(.bold, size: 20))
            
            Spacer()
            
            Menu {
                Button {
                    viewModel.clearMessages()
                } label: {
                    Label("대화 초기화", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .padding()
        .background(.background2Ws)
    }
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatbotBubble(message: message)
                            .id(message.id)
                    }
                    
                    // 로딩 인디케이터
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("답변 생성 중...")
                                .font(.pretendard(.regular, size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                // 새 메시지가 추가되면 스크롤
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { _ in
                // 로딩 상태 변경시에도 스크롤
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("메시지를 입력하세요", text: $inputText)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.mainws, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                )
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? .gray : .mainws)
            }
            .disabled(inputText.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(.background2Ws)
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !viewModel.isLoading else { return }
        
        Task {
            await viewModel.sendMessage(inputText)
            inputText = ""
        }
        isInputFocused = false
    }
}
