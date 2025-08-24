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

struct ProfileImageRequest: Encodable {
    let image: Int   // 1~4
}

struct ProfileImageResponse: Decodable {
    let message: String?
    let error: String?
    let statusCode: Int?
    let profileImage: String?
    let profileImageUrl: String?
    let path: String?
}

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
    func signUp(name: String, email: String, password: String, birth: String, isMentor: Bool) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APISignupURL") as? String else {
            print("URL이 존재하지 않습니다.")
            throw UserAPIError.invalidEndPoint
        }
        
        print("API 엔드포인트: \(endPoint)")
        
        let targetLanguage = getTargetLanguage()
        
        print("targetLanguage: \(targetLanguage)")
        
        let parameters: [String: Any] = [
            "userEmail": email,
            "password": password,
            "userName": name,
            "userBirth": birth,
            "isMentor": isMentor,
            "targetLanguage": targetLanguage
        ]
        
        print("요청 파라미터: \(parameters)")

        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .serializingData()
            .response
        
        print("응답 결과: \(dataResponse.result)")
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                print("signup: \(response)")
                
                return response
            } catch {
                print("디코딩 에러: \(error.localizedDescription)")

                if let rawJSON = String(data: data, encoding: .utf8) {
                    // print("원본 JSON 응답:\n\(rawJSON)")
                }
                
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                // print("회원가입 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("회원가입 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "signup 서버 응답 파싱 실패")
            }
        }
    }
    
    // 로그인
    func login(email: String, password: String) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APILoginURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        print("API 엔드포인트: \(endPoint)")
        
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
                
                // 유저 토큰 저장
                UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                
                do {
                    let userInfoResponse = try await self.getUserInfo()
                    if let userId = userInfoResponse.userInfo?.id {
                        UserDefaults.standard.set(userId, forKey: "userId")
                        print("getUserInfo로 userId 저장:", userId)
                    } else {
                        print("getUserInfo 응답에 userId 없음!")
                    }
                } catch {
                    print("userId 저장용 getUserInfo 실패:", error)
                }

                // 유저 이름 저장
                UserDefaults.standard.set(response.username, forKey: "username")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "Login 디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                // print("로그인 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("로그인 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "login 서버 응답 파싱 실패")
            }
        }
    }
    
    // 프로필 이미지 설정
    func updateProfileImage(imageNumber: Int) async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIProfileImageURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
                                
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let parameters: [String: Any] = [
            "image": imageNumber
        ]
              
        let response = try await AF.request(endPoint, method: .post, parameters: parameters, headers: headers)
            .serializingDecodable(APIResponse.self)
            .value
        
        return response
    }

    func attendanceCheck() async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
                
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIUserAttendanceURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
                
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let dataResponse = await AF.request(endPoint, method: .post, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .serializingData()
            .response
                
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                print("출석체크 정보: \(response)")

                return response
            } catch {
                print("디코딩 에러: \(error.localizedDescription)")
                
                if let rawJSON = String(data: data, encoding: .utf8) {
                     print("출석체크 원본 JSON 응답:\n\(rawJSON)")
                }
                
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("출석체크 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("출석체크 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "출석체크 서버 응답 파싱 실패")
            }
        }
    }
    
    func getAttendanceList() async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
                
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIUserAttendanceListURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
                
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let dataResponse = await AF.request(endPoint, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .serializingData()
            .response
                
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                // print("출석체크 정보: \(response)")

                return response
            } catch {
                print("디코딩 에러: \(error.localizedDescription)")
                
                if let rawJSON = String(data: data, encoding: .utf8) {
                     print("출석체크 원본 JSON 응답:\n\(rawJSON)")
                }
                
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("출석체크 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("출석체크 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "출석체크 서버 응답 파싱 실패")
            }
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
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("이메일 중복 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "이메일 중복 서버 응답 파싱 실패")
            }
        }
    }
    
    // 이메일 코드 체크
    func emailVerifyCode(email: String, verifyCode: String) async throws -> APIResponse {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIEmailCodeURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "email": email,
            "verificationCode": verifyCode
        ]
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("이메일 코드 정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "User 디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("이메일 중복 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "이메일 중복 서버 응답 파싱 실패")
            }
        }
    }
    
    // 액세스 토큰 재발급
    // 액세스, 리프레시 모두 유저디폴트에 저장할 듯
    func getNewAccessToken() async throws -> APIResponse {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refreshToken") else {
            print("refreshToken 토큰 값이 유효하지 않습니다.")
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
                
                UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
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
        
        let dataResponse = await AF.request(endPoint, method: .post, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                
                print("로그아웃 정보: \(response)")
                
                UserDefaults.standard.removeObject(forKey: "accessToken")
                UserDefaults.standard.removeObject(forKey: "refreshToken")
                UserDefaults.standard.removeObject(forKey: "username")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 회원탈퇴
    func deleteAccount(withdrawalReason: String = "personal") async throws -> APIResponse {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        print("현재 토큰: \(token)")
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIDeleteAccountURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
                
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        print("요청 헤더: \(headers)")
        
        let parameters: [String: Any] = [
            "withdrawalReason": withdrawalReason
        ]
        
        print("요청 파라미터: \(parameters)")
        
        let dataResponse = await AF.request(endPoint, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .serializingData()
            .response
                
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                print("회원탈퇴 정보: \(response)")
                
                UserDefaults.standard.removeObject(forKey: "accessToken")
                UserDefaults.standard.removeObject(forKey: "refreshToken")
                UserDefaults.standard.removeObject(forKey: "username")
                
                return response
            } catch {
                print("디코딩 에러: \(error.localizedDescription)")
                
                if let rawJSON = String(data: data, encoding: .utf8) {
                     print("회원탈퇴 원본 JSON 응답:\n\(rawJSON)")
                }
                
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("회원탈퇴 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("회원탈퇴 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "회원탈퇴 서버 응답 파싱 실패")
            }
        }
    }
    
    // 사용자 정보 조회
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
                                
                UserDefaults.standard.set(response.userInfo?.userName, forKey: "username")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
        }
    }
    
    // 비밀번호 변경
    func resetPassword(oldPassword: String, newPassword: String) async throws -> APIResponse {
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
    
    // OCR 번역
    func OCRTranslation(file: Data) async throws -> OCR {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIOCRURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let parameters: [String: Any] = [
            "files": file
        ]
        
        let dataResponse = await AF.upload(multipartFormData: { multipartFormData in multipartFormData.append(file, withName: "files", fileName: "ocr_image.jpg", mimeType: "image/jpeg")}, to: endPoint, method: .post, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(OCR.self, from: data)
                
                print("OCR 정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "OCR 디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("OCR 체크 서버 원본 응답: \(rawString)")
                
                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                    print("OCR 체크 파싱된 에러 응답: \(errorResponse)")
                    
                    var errorMessage = errorResponse.error
                    
                    throw UserAPIError.serverError(message: errorMessage)
                } catch {
                    print("OCR 체크 에러 응답 파싱 실패: \(error)")
                    throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
                }
            } else {
                throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
            }
        }
    }
    
    // OCR 핵심 개념
    func OCRSummary() async throws -> OCRSolution {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIOCRSolutionURL") as? String else {
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
                let response = try JSONDecoder().decode(OCRSolution.self, from: data)
                
                print("OCRSummary 정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "OCRSummary 디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("OCR 체크 서버 원본 응답: \(rawString)")
                
                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                    print("OCR 체크 파싱된 에러 응답: \(errorResponse)")
                    
                    var errorMessage = errorResponse.error
                    
                    throw UserAPIError.serverError(message: errorMessage)
                } catch {
                    print("OCR 체크 에러 응답 파싱 실패: \(error)")
                    throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
                }
            } else {
                throw UserAPIError.serverError(message: "서버 응답 파싱 실패")
            }
        }
    }
    
    //내가 한 질문 목록 조회 -> 추후 API Service로 이동
    func getMyQuestions() async throws -> [QuestionList] {
        
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIMyQuestionURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
                
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
              
        let response = try await AF.request(endPoint, method: .get, headers: headers)
            .serializingDecodable([QuestionList].self)
            .value
        
        return response
    }
    
    func getOCRList(userID: Int) async throws -> [OCRList] {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "APIOCRURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        let endPoint = "\(baseURL)/\(userID)"
                
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
              
        let response = try await AF.request(endPoint, method: .get, headers: headers)
            .serializingDecodable([OCRList].self)
            .value
        
        return response
    }
    
    func getCultureInfo() async throws -> CultureInfo {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APICrawlURL") as? String else {
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
                let response = try JSONDecoder().decode(CultureInfo.self, from: data)
                
                // print("문화정보: \(response)")
                
                return response
            } catch {
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("getCultureInfo 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                print("getCultureInfo 파싱된 에러 응답: \(errorResponse)")
                
                let errorMessage = errorResponse.message[0]
                throw UserAPIError.serverError(message: errorMessage)
            } else {
                throw UserAPIError.serverError(message: "getCultureInfo 서버 응답 파싱 실패")
            }
        }
    }
}

// MARK: - UserAPIManager Extension 수정
extension UserAPIManager {
    func getTargetLanguage() -> String {
        return SupportedLanguage.getCurrentLanguageCode()
    }
    
    func getTargetLanguageName() -> String {
        return SupportedLanguage.getCurrentLanguageName()
    }
}
