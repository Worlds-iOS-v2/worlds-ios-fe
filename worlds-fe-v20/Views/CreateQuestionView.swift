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

    // ✅ enum 기반 선택된 카테고리
    @State private var selectedCategory: Category? = nil

    var onSubmit: (_ images: [UIImage], _ category: String) -> Void

    var body: some View {
        NavigationView {
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                Spacer().frame(height: 15)

                // ✅ 카테고리 선택 (enum 기반)
                Menu {
                    ForEach([Category.study, Category.free], id: \.self) { category in
                        Button(category.displayName) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCategory?.displayName ?? "게시판 선택")
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
                .padding(.horizontal, 4)

                // 제목 입력
                TextField("제목", text: $title)
                    .padding(13)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 105/255, green: 131/255, blue: 255/255), lineWidth: 1)
                    )
                    .font(.system(size: 17))
                    .padding(.horizontal, 4)

                // 내용 입력
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
                .padding(.horizontal, 4)

                // 이미지 선택 영역
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
                .padding(.horizontal, 4)

                Spacer()

                // 등록 버튼
                Button {
                    guard let selected = selectedCategory else {
                        errorMessage = "카테고리 선택은 필수입니다."
                        return
                    }
                    onSubmit(selectedImages, selected.rawValue) // ✅ 서버로 "study"/"free" 전송
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
                .padding(.horizontal, 4)
                }
            } // Close ScrollView
            .padding(.horizontal, 20)
            .navigationTitle("질문하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
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
            .onDisappear {
                title = ""
                content = ""
                selectedImages = []
                selectedCategory = nil
            }
        }
    }
}
