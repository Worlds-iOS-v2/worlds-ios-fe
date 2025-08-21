//
//  ProfileImageSelectionView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/20/25.
//

import SwiftUI

struct ProfileImageSelectionView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedCharacter: Int? = nil
    @State private var isUpdatingProfile = false
        
    // 캐릭터 정보 (번호 순서: 1, 2, 3, 4)
    let characters = [
        CharacterInfo(number: 1, imageName: "himchan", name: "힘찬이", color: Color.blue.opacity(0.2)),
        CharacterInfo(number: 2, imageName: "doran", name: "도란이", color: Color.yellow.opacity(0.2)),
        CharacterInfo(number: 3, imageName: "malgeum", name: "맑음이", color: Color.yellow.opacity(0.3)),
        CharacterInfo(number: 4, imageName: "saengak", name: "생각이", color: Color.orange.opacity(0.2))
    ]
    
    var body: some View {
        ZStack {
            Color.background1Ws
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Button {
                    appState.flow = .login
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                
                VStack(spacing: 16) {
                    Text("캐릭터 선택")
                        .font(.pretendard(.bold, size: 32))
                        .foregroundStyle(.mainfontws)
                    
                    Text("함께 공부할 캐릭터를 골라보세요!")
                        .font(.pretendard(.medium, size: 18))
                        .foregroundStyle(.gray)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // 캐릭터 선택 그리드
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 30) {
                    ForEach(characters, id: \.number) { character in
                        CharacterCardView(
                            character: character,
                            isSelected: selectedCharacter == character.number
                        ) {
                            selectedCharacter = character.number
                            selectProfile(character.number)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            
            // 로딩 오버레이
            if isUpdatingProfile {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView("프로필 설정 중...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func selectProfile(_ characterNumber: Int) {
        guard !isUpdatingProfile else { return }
        
        isUpdatingProfile = true
        
        Task {
            do {
                // 프로필 이미지 업데이트 API 호출 (번호로 전송)
                try await UserAPIManager.shared.updateProfileImage(imageNumber: characterNumber)
                
                await MainActor.run {
                    isUpdatingProfile = false
                    appState.flow = .main
                }
            } catch {
                await MainActor.run {
                    isUpdatingProfile = false
                    print("프로필 이미지 업데이트 실패: \(error)")
                    // 에러 처리 로직 추가 가능
                }
            }
        }
    }
}

struct CharacterInfo {
    let number: Int
    let imageName: String
    let name: String
    let color: Color
}

struct CharacterCardView: View {
    let character: CharacterInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(character.color)
                        .frame(width: 140, height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.mainws : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // 캐릭터 이미지 (실제 이미지로 교체 필요)
                    Image(character.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: animationOffset
                        )
                }
                
                Text(character.name)
                    .font(.pretendard(.semiBold, size: 20))
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            // 각 캐릭터마다 다른 딜레이로 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...1)) {
                animationOffset = -8
            }
        }
    }
}

#Preview {
    ProfileImageSelectionView()
        .environmentObject(AppState())
}
