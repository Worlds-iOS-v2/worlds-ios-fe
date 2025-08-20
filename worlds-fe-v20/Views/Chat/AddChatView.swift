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
    @State private var pairingToken: String?        // QR에 들어갈 일회용 토큰
    @State private var pairingExpiresAt: String?    // 만료 시간 (표시/관리 용)
    @State private var showAlert = false
    @State private var errorMessage: String? = nil
    @State private var activeChatRoom: ChatRoom?
    @State private var pendingChatRoom: ChatRoom?
    
    var textColor: Color = .mainfontws

    var body: some View {
        NavigationStack {
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
                        .font(.bmjua(.regular, size: 20))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    // 오른쪽 공간 확보용
                    Spacer().frame(width: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                VStack(spacing: 8) {
                    Text("QR로 채팅 상대를 추가하세요")
                        .font(.bmjua(.regular, size: 22))
                        .foregroundColor(textColor)
                    
                    Text("상대방의 QR 코드를 스캔하면\n자동으로 채팅방이 생성돼요.")
                        .font(.bmjua(.regular, size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .shadow(radius: 4)
                    .overlay(
                        Group {
                            if let token = pairingToken, let qrImage = generateQRCode(from: token) {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                            } else {
                                Text("QR 생성 준비 중…")
                                    .font(.bmjua(.regular, size: 18))
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                    .padding(.top, 24)
                
                Button(action: {
                    isShowingScanner = true
                }) {
                    Text("QR 스캔하기")
                        .font(.bmjua(.regular, size: 20))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.mainws)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 3)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .sheet(isPresented: $isShowingScanner, onDismiss: {
                    // 시트(스캐너)가 완전히 내려간 뒤에 네비게이션 푸시 수행
                    if let room = pendingChatRoom {
                        self.activeChatRoom = room
                        self.pendingChatRoom = nil
                    }
                }) {
                    QRCodeScannerView { token in
                        // 스캔 성공 → claim 호출, 결과는 pending으로 보관
                        SocketService.shared.claimPairing(token: token) { chatRoom in
                            DispatchQueue.main.async {
                                if let chatRoom = chatRoom {
                                    self.pendingChatRoom = chatRoom
                                } else {
                                    self.errorMessage = "채팅방 생성에 실패했어요. 다시 시도해주세요."
                                    self.showAlert = true
                                }
                                // 시트 닫기 (닫힌 뒤 onDismiss에서 push)
                                self.isShowingScanner = false
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .background(Color(red: 0.94, green: 0.96, blue: 1.0))
            .ignoresSafeArea()
            .onAppear {
                SocketService.shared.createPairingToken { token, expiresAt in
                    DispatchQueue.main.async {
                        if let token = token {
                            self.pairingToken = token
                            self.pairingExpiresAt = expiresAt
                        } else {
                            self.errorMessage = "QR 생성에 실패했어요. 다시 시도해주세요."
                            self.showAlert = true
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("알림"),
                      message: Text(errorMessage ?? "알 수 없는 오류가 발생했습니다."),
                      dismissButton: .default(Text("확인")))
            }
            .fullScreenCover(item: $activeChatRoom) { room in
                ChatDetailView(chat: room)
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        print("QR 생성 시도: \(string)")

        guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
            print("토큰 UTF-8 인코딩 실패")
            return nil
        }

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
