//
//  ChatListViewModel.swift
//  worlds-fe-v20
//
//  Created by 이다은 on 2025/08/05.
//

import Foundation
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    private var cancellables = Set<AnyCancellable>()

    func fetchChatRooms(for userId: Int) {
        // NOTE: 서버가 JWT로 사용자 식별하므로 userId는 더 이상 경로에 포함하지 않습니다.
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseURL)/chat/chatrooms") else {
            print("Invalid URL or missing APIBaseURL")
            return
        }

        guard let accessToken = UserDefaults.standard.string(forKey: "accessToken") else {
            print("❌ accessToken 없음: 채팅방 목록을 불러올 수 없습니다.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [ChatRoom].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error fetching chat rooms:", error)
                }
            }, receiveValue: { [weak self] rooms in
                self?.chatRooms = rooms
            })
            .store(in: &self.cancellables)
    }
}
