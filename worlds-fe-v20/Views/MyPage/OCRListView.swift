//
//  OCRListView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/19/25.
//

import SwiftUI

struct OCRListView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var ocrList: [QuestionList] = []

    var body: some View {
        ZStack {
            Color.backgroundws
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(ocrList) { ocr in
//                        NavigationLink(destination: OCRResultView(isOCRList: true)) {
//                                QuestionCard(question: ocr, thumbnailURLString: nil)
//                            }
//                            .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }
            .navigationTitle("나의 OCR 목록")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.mainws)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
    }
}

struct OCRCardView: View {
    let OCRContent: QuestionList
    let thumbnailURLString: String?
    
    private var thumbnailURL: URL? {
        guard let s = thumbnailURLString, let url = URL(string: s) else { return nil }
        return url
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: texts
            VStack(alignment: .leading, spacing: 6) {
                Text(OCRContent.category.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.systemGray))
                    .padding(.top, 8)
                
                HStack(alignment: .center, spacing: 8) {
                    Text(OCRContent.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if OCRContent.answerCount > 0 {
                        Text("답변 \(OCRContent.answerCount)개")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(Color.mainws)
                            .cornerRadius(14)
                    }
                    Spacer()
                }
                .padding(.top, 2)
                
                Text(OCRContent.content)
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(2)
                    .padding(.bottom, 6)
                
                Spacer(minLength: 0)
            }
            
            // Right: thumbnail
            if let url = thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 72, height: 72)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray3))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
    }
}
