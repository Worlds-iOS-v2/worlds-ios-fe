//
//  UserAPIManager.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 7/8/25.
//

// User CRUD 관련 API 코드 => 충돌 날까봐 따로 코드 작성 / 추후 APIService에 합칠 것임
import Foundation
import Alamofire
import UIKit

enum UserAPIError: Error, LocalizedError {
    case missingToken
    case invalidToken
    case invalidEndPoint
    case serverError(message: String)
    case decodingError(description: String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidEndPoint:
            return "API 엔드포인트가 잘못되었습니다."
        case .serverError(let message):
            return message
        case .decodingError(let description):
            return description
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        case .missingToken:
            return "토큰이 없습니다."
        case .invalidToken:
            return "사용할 수 없는 토큰입니다."
        }
    }
}

class UserAPIManager {
    static let shared = UserAPIManager()
    
    let baseURL = "http://localhost:3000"
    
    func getToken() -> String? {
        // UserDefaults.standard.set(token, forKey: "accessToken")
        return UserDefaults.standard.string(forKey: "accessToken")
    }
    
    // 토큰이 필요한 API 호출을 위한 헤더 생성
    private func getAuthHeaders() -> HTTPHeaders? {
        guard let token = getToken() else {
            return nil
        }
        return ["Authorization": "Bearer \(token)"]
    }
    
    private func saveUserInfo(response: User) {
        if let encoded = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(encoded, forKey: "user")
        }
    }
    
    func signUp(name: String, email: String, password: String, isTeacher: Bool) async throws -> User {
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APISignUpURL") as? String else {
            print("URL이 존재하지 않습니다.")
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "email": email,
            "name": name,
            "password": password,
        ]
        
        let response = try await AF.request(endPoint, method: .post, parameters: parameters)
            .serializingDecodable(User.self, decoder: JSONDecoder())
            .value
        
        // 유저 정보 저장
        /// 유저 정보 저장하는게 필요한지 다시 고려해보기
        saveUserInfo(response: response)
        
        return response
    }
    
    func login(email: String, password: String) async throws -> User {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APILoginURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "email": email,
            "password": password,
        ]
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                
                // 유저 정보 저장
                saveUserInfo(response: user)
                
                // 유저 토큰 저장
                // UserDefaults.standard.set(user.accessToken, forKey: "accessToken")
                
                print("로그인 성공")
                
                if let savedData = UserDefaults.standard.data(forKey: "user"),
                   let savedUser = try? JSONDecoder().decode(User.self, from: savedData) {
                    print(user)
                }
                
                return user
            } catch {
                throw UserAPIError.decodingError(description: "User 디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
//            if let data = dataResponse.data {
//                if let serverError = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
//                    throw UserAPIError.serverError(message: serverError.message.joined(separator: ", "))
//                } else {
//                    throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
//                }
//            } else {
//                throw UserAPIError.unknown
//            }
        }
    }
}
