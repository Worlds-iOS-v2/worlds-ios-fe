//
//  OCRListView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/19/25.
//

import SwiftUI

struct OCRListView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var ocrList: [OCRList] = []

    var body: some View {
        ZStack {
            Color.background2Ws
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(ocrList) { ocr in
                        NavigationLink(destination: OCRListDetailView(ocrContent: ocr)) {
                            OCRCardView(OCRContent: ocr)
                        }
                        .buttonStyle(PlainButtonStyle())
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
    let OCRContent: OCRList
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(OCRContent.keyConcept)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.systemGray))
                    .padding(.top, 8)
                
                HStack(alignment: .center, spacing: 8) {
                    Text(OCRContent.summary)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding(.top, 2)
                
                Text(OCRContent.createdAt)
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(2)
                    .padding(.bottom, 6)
                
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
    }
}

#Preview {
    OCRListView()
}
