//
//  QuestionDetailView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
// TODO: 이미지 등록 안댄다...zz

import SwiftUI

struct QuestionDetailView: View {
    let question: QuestionList
    @State private var goToCreateAnswerView = false
    @State private var showActionSheet = false
    
    let badgeColorMap: [String: Color] = [
        "학습 게시판": Color.blue,
        "자유 게시판": Color.purple,
        "전체 보기": Color.gray
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    showActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(title: Text("옵션"), buttons: [
                    .default(Text("신고")) {},
                    .destructive(Text("삭제")) {},
                    .cancel()
                ])
            }
            
            // 카테고리 뱃지
            HStack {
                Text(question.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(badgeColorMap[question.category.rawValue] ?? .gray)
                    .cornerRadius(16)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            //유저표시
            HStack(spacing: 10) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .foregroundColor(.gray)
                VStack(alignment: .leading, spacing: 2) {
                    Text(question.user.name ?? "유저이름")
                        .font(.callout)
                        .fontWeight(.bold)
                    Text(formatDate(question.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // 제목
            Text(question.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 18)
                .padding(.horizontal)
            
            // 본문
            Text(question.content)
                .font(.body)
                .foregroundColor(.black)
                .padding(.top, 10)
                .padding(.horizontal)
            
            // 번역하기
            Button("번역하기") {
                // 상세
            }
            .font(.callout)
            .foregroundColor(.blue)
            .padding(.horizontal)
            .padding(.top, 14)
            
            Divider()
                .padding(.top, 16)
            
            Spacer()
            
            // 답변 작성하기 버튼
            Button(action: {
                goToCreateAnswerView = true
            }) {
                Text("답변 작성하기")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding()
                    .frame(width: 150)
                    .background(Color("darkbrown"))
                    .cornerRadius(25)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.white)
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    func formatDate(_ dateStr: String) -> String {
        // "2025-07-14T10:25:00.000Z" → "2025/07/14 10:25"
        let inputFormatter = ISO8601DateFormatter()
        if let date = inputFormatter.date(from: dateStr) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            return formatter.string(from: date)
        }
        return dateStr.prefix(10) + " " + dateStr.dropFirst(11).prefix(5)
    }
}
