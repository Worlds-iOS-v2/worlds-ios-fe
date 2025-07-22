//
//  QuestionDetailView.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//
//  TODO: 이미지 등록 안댄다...zz

import SwiftUI

struct QuestionDetailView: View {
    let question: QuestionList
    @State private var goToCreateAnswerView = false
    @State private var showOptions = false
    @State private var showReportReasons = false
    @State private var showDeleteAlert = false
    @ObservedObject var viewModel: QuestionViewModel
    @Environment(\.presentationMode) var presentationMode

    let reportReasons: [(label: String, value: ReportReason)] = [
        ("비속어", .offensive),
        ("음란", .sexual),
        ("광고", .ad),
        ("기타", .etc)
    ]

    let badgeColorMap: [String: Color] = [
        "학 습": .blue,
        "자 유": .purple,
        "전 체": .gray
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // 카테고리 뱃지 + ... 버튼
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

                    Button {
                        showOptions = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.degrees(90))
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 12) // 유저 정보와 간격 확보

                // 유저 정보
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 38, height: 38)
                        .foregroundColor(.gray)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(question.user.name)
                            .font(.callout)
                            .fontWeight(.bold)
                        Text(formatDate(question.createdAt))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 0)

                // 제목
                Text(question.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 24)
                    .padding(.horizontal)

                // 본문
                Text(question.content)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.top, 18)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)

                // 번역 버튼 (더미)
                Button("번역하기") {
                    // 번역 기능
                }
                .font(.callout)
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.top, 14)

                Divider()
                    .padding(.top, 16)

                Spacer()

                // 답변 작성 버튼
                Button(action: { goToCreateAnswerView = true }) {
                    Text("답변 작성하기")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .padding()
                        .frame(width: 150)
                        .background(Color("darkbrown"))
                        .cornerRadius(25)
                }
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(Color.white)
        }
        // 네비게이션
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
        }
        // 옵션 다이얼로그
        .confirmationDialog("옵션", isPresented: $showOptions, titleVisibility: .visible) {
            Button("신고") {
                showReportReasons = true
            }
            Button("삭제", role: .destructive) {
                Task {
                    try await viewModel.deleteQuestion(id: question.id)
                    showDeleteAlert = true
                }
            }
            Button("취소", role: .cancel) {}
        }
        // 신고 사유 다이얼로그
        .confirmationDialog("신고 사유를 선택하세요", isPresented: $showReportReasons, titleVisibility: .visible) {
            ForEach(reportReasons, id: \.value) { reason in
                Button(reason.label) {
                    Task {
                        try? await viewModel.reportQuestion(questionId: question.id, reason: reason.value)
                    }
                }
            }
            Button("취소", role: .cancel) {}
        }
        // 삭제 완료 알림
        .alert("질문이 삭제되었습니다.", isPresented: $showDeleteAlert) {
            Button("확인") {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    func formatDate(_ dateStr: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        if let date = inputFormatter.date(from: dateStr) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            return formatter.string(from: date)
        }
        return dateStr.prefix(10) + " " + dateStr.dropFirst(11).prefix(5)
    }
}
