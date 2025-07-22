//
//  CreateQuestionView.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/8/25.
//

import SwiftUI

struct CreateQuestionView: View {
    @Binding var title: String
    @Binding var content: String
    @Binding var isPresented: Bool
    @Binding var isCreating: Bool
    @Binding var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedCategory = ""
    
    let categories = ["학습 게시판", "자유 게시판"]
    let categoryMap = ["학습 게시판": "study", "자유 게시판": "free"]
    
    var categoryValue: String {
        categoryMap[selectedCategory] ?? selectedCategory
    }
    var onSubmit: (_ images: [UIImage], _ category: String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 14) {
                Spacer().frame(height: 15)
                
                // 게시판 카테고리 선택
                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button(category) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory.isEmpty ? "게시판 선택" : selectedCategory)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 0)
                
                // 제목
                TextField("제목", text: $title)
                    .padding(13)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 105/255, green: 131/255, blue: 255/255), lineWidth: 1)
                    )
                    .font(.system(size: 17))
                
                // 내용
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("내용")
                            .foregroundColor(Color(.systemGray3))
                            .padding(.top, 13)
                            .padding(.leading, 17)
                    }
                    TextEditor(text: $content)
                        .padding(8)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 105/255, green: 131/255, blue: 255/255), lineWidth: 1)
                        )
                        .font(.system(size: 17))
                        .frame(height: 370)
                }
                
                
                HStack {
                    Button {
                        imagePickerSourceType = .photoLibrary
                        isShowingImagePicker = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .frame(width: 32, height: 28)
                                .foregroundColor(Color(.systemGray))
                            Text("\(selectedImages.count)/3")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 48)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 105/255, green: 131/255, blue: 255/255), lineWidth: 1.2)
                        )
                    }
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.leading, 30)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 4)
                
                Spacer()
                
                Button {
                    if selectedCategory.isEmpty {
                        errorMessage = "카테고리 선택은 필수입니다."
                        return
                    }
                    onSubmit(selectedImages, categoryValue)
                } label: {
                    Text("등록")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color(red: 105/255, green: 131/255, blue: 255/255))
                        .cornerRadius(13)
                        .shadow(color: Color(.systemGray3), radius: 3, x: 0, y: 3)
                }
                .padding(.bottom, 18)
                
            }
            .padding(.horizontal, 10)
            .navigationTitle("질문하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                if imagePickerSourceType == .camera {
                    CameraPickerView(selectedImages: $selectedImages)
                } else {
                    ImagePickerView(selectedImages: $selectedImages)
                }
            }
        }
    }
}
