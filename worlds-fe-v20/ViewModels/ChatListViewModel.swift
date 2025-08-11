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
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: "\(baseURL)/chatrooms/\(userId)") else {
            print("Invalid URL or missing APIBaseURL")
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [ChatRoom].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching chat rooms: \(error)")
                }
            }, receiveValue: { [weak self] rooms in
                self?.chatRooms = rooms
            })
            .store(in: &cancellables)
    }
}
