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
    
    // 회원가입
    func signUp(name: String, email: String, password: String, birth: String, isMentor: Bool, mentorCode: String?) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APISignupURL") as? String else {
            print("URL이 존재하지 않습니다.")
            throw UserAPIError.invalidEndPoint
        }
        
        let targetLanguage = getTargetLanguage()
        
        print("targetLanguage: \(targetLanguage)")
        
        let parameters: [String: Any] = [
            "userEmail": email,
            "password": password,
            "userName": name,
            "userBirth": birth,
            "isMentor": isMentor,
            "mentorCode": mentorCode,
            "targetLanguage": targetLanguage
        ]
        
        let response = try await AF.request(endPoint, method: .post, parameters: parameters)
            .serializingDecodable(APIResponse.self, decoder: JSONDecoder())
            .value
        
        print("회원가입 결과: \(response)")
        
        // 유저 정보 저장
        /// 유저 정보 저장하는게 필요한지 다시 고려해보기
        // saveUserInfo(response: response)
        
        return response
    }
    
    // 로그인
    func login(email: String, password: String) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APILoginURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "userEmail": email,
            "password": password,
        ]
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("로그인 정보: \(response)")
                // 유저 정보 저장
                // saveUserInfo(response: user)
                
                // 유저 토큰 저장
                UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                
                print("로그인 성공")
                //
                //                if let savedData = UserDefaults.standard.data(forKey: "user"),
                //                   let savedUser = try? JSONDecoder().decode(User.self, from: savedData) {
                //                    print(user)
                //                }
                
                return response
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
    
    // 이메일 중복 체크
    func emailCheck(email: String) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APICheckEmailURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "userEmail": email
        ]
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("이메일 중복 정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "User 디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 액세스 토큰 재발급
    // 액세스, 리프레시 모두 유저디폴트에 저장할 듯
    func getNewAccessToken() async throws -> APIResponse {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIAccessTokenURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "refreshToken": refreshToken,
        ]
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("액세스 토큰 재발급: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "User 디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 로그아웃
    func logout() async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APILogoutURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let dataResponse = await AF.request(endPoint, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("로그아웃 정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 사용자 정보 조히
    func getUserInfo() async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIUserInfoURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let dataResponse = await AF.request(endPoint, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("사용자 정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 비밀번호 변경
    func changePassword(oldPassword: String, newPassword: String) async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIChangePasswordURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let parameters: [String: Any] = [
            "org_password": oldPassword,
            "new_password": newPassword
        ]
        
        let dataResponse = await AF.request(endPoint, method: .patch, parameters: parameters, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("비밀번호 변경: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 이거 request Body에 뭘 넣어야하는 것임? email? username?
    func findEmail(name: String) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIFindEmailURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "userName": name
        ]
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("이메일 찾기: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "User 디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
}

extension UserAPIManager {
    func getTargetLanguage() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en" //ko-KR
        let languageCode = preferredLanguage.components(separatedBy: "-").first ?? "en" //ko만 출력
        
        // 서버에서 요구하는 형태로 매핑
        switch languageCode.lowercased() {
        case "ko":
            return "Korean"
        case "en":
            return "English"
        case "vi":
            return "Vietnam"
        case "ja":
            return "Japanese"
        case "zh":
            return "Chinese"
        case "es":
            return "Spanish"
        case "fr":
            return "French"
        default:
            return "English" // 기본값
        }
    }
}
