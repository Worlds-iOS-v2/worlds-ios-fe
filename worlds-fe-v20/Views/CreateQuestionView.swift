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
            VStack(alignment: .leading, spacing: 16) {
                
                TextField("제목", text: $title)
                    .padding(12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("darkbrown"), lineWidth: 2)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                //카테고리 선택 + 사진추가
                HStack {
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory.isEmpty ? "카테고리 선택" : selectedCategory)
                            Image(systemName: "chevron.down")
                        }
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    
                    Menu("사진 추가하기") {
                        Button("Camera") {
                            imagePickerSourceType = .camera
                            isShowingImagePicker = true
                        }
                        Button("Photo") {
                            imagePickerSourceType = .photoLibrary
                            isShowingImagePicker = true
                        }
                    }
                }
                .padding(.horizontal)
                
                //사진 여러장
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
                
                
                TextEditor(text: $content)
                    .padding(10)
                    .frame(height: 300)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color("darkbrown"), lineWidth: 2)
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                //등록되는 동안 로딩
                if isCreating {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                
                Button {
                    if selectedCategory.isEmpty {
                        errorMessage = "카테고리 선택은 필수입니다."
                        return
                    }
                    onSubmit(selectedImages, categoryValue) //selectedCategory전달하면 한글이라 서버 못받
                } label: {
                    Text("등록")
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                        .padding()
                        .frame(width: 150)
                        .background(Color("lightbrown"))
                        .cornerRadius(25)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 30)
                
                Spacer()
            }
            .padding()
            .navigationTitle("질문하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .padding(.leading, 15)
                            .frame(width: 20, height: 30)
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


