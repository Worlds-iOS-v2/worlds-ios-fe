//
//  AddChatView.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 8/7/25.
//

import SwiftUI
import CoreImage
import UIKit

struct AddChatView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var showAlert = false
    @State private var navigateToChat = false
    @State private var activeChatRoom: ChatRoom?

    var body: some View {
        NavigationStack {
            NavigationLink(
                destination: activeChatRoom.map { ChatDetailView(chat: $0) },
                isActive: $navigateToChat
            ) {
                EmptyView()
            }
            VStack(spacing: 24) {
            // 상단 바
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.black)
                }
                Spacer()
                Text("대화상대추가")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                // 오른쪽 공간 확보용
                Spacer().frame(width: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text("QR로 채팅 상대를 추가하세요")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("상대방의 QR 코드를 스캔하면\n자동으로 채팅방이 생성돼요.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 280, height: 280)
                .shadow(radius: 4)
                .overlay(
                    Group {
                        if let userId = UserDefaults.standard.string(forKey: "userId"),
                           let qrImage = generateQRCode(from: userId) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                        } else {
                            Text("QR 생성 실패")
                                .foregroundColor(.red)
                        }
                    }
                )
                .padding(.top, 24)

            Button(action: {
                isShowingScanner = true
            }) {
                Text("QR 스캔하기")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(14)
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .sheet(isPresented: $isShowingScanner) {
                QRCodeScannerView { code in
                    scannedCode = code
                    isShowingScanner = false
                    SocketService.shared.createChatRoom(with: code) { chatRoom in
                        DispatchQueue.main.async {
                            if let chatRoom = chatRoom {
                                self.activeChatRoom = chatRoom
                                self.navigateToChat = true
                                print("채팅방 생성 성공")
                            } else {
                                self.showAlert = true
                                print("채팅방 생성 실패")
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .background(Color(red: 0.94, green: 0.96, blue: 1.0))
        .ignoresSafeArea()
        // Optional: show alert with scanned code
        .alert(isPresented: $showAlert) {
            Alert(title: Text("QR 코드 인식"),
                  message: Text(scannedCode ?? ""),
                  dismissButton: .default(Text("확인")))
        }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        print("QR 생성 시도: \(string)")

        let data = string.data(using: .ascii)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("필터 생성 실패")
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else {
            print("outputImage 생성 실패")
            return nil
        }

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("CGImage 생성 실패")
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    AddChatView()
}
