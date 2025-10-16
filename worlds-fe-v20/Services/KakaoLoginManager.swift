//
//  KakaoLoginManager.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 9/8/25.
//

import SwiftUI
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKCommon
import Alamofire

// MARK: - 카카오 로그인 매니저
class KakaoLoginManager: ObservableObject {
    @Published var isLoggedIn = false
    
    init() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "KakaoNativeAppKey") as? String else {
            print("appKey가 존재하지 않습니다.")
            return
        }
        
        KakaoSDK.initSDK(appKey: appKey)
    }
    
    func loginWithKakao(completion: @escaping (Result<Bool, Error>) -> Void) {
        // 카카오톡이 설치되어 있으면 카카오톡으로 로그인, 아니면 웹으로 로그인
        if UserApi.isKakaoTalkLoginAvailable() {
            loginWithKakaoTalk(completion: completion)
        } else {
            loginWithKakaoAccount(completion: completion)
        }
    }
    
    private func loginWithKakaoTalk(completion: @escaping (Result<Bool, Error>) -> Void) {
        UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
            self?.handleLoginResult(oauthToken: oauthToken, error: error, completion: completion)
        }
    }
    
    private func loginWithKakaoAccount(completion: @escaping (Result<Bool, Error>) -> Void) {
        UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
            self?.handleLoginResult(oauthToken: oauthToken, error: error, completion: completion)
        }
    }
    
    private func handleLoginResult(oauthToken: OAuthToken?, error: Error?, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let error = error {
            print("=== 카카오 로그인 에러 ===")
            print("Error: \(error.localizedDescription)")
            print("=====================")
            completion(.failure(error))
            return
        }
        
        guard let token = oauthToken else {
            completion(.failure(NSError(domain: "KakaoLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "토큰을 받을 수 없습니다."])))
            return
        }
        
        print("=== 카카오 토큰 정보 ===")
        print("Access Token: \(token.accessToken)")
        print("=====================")
        
        // 토큰 전달
        Task {
            do {
                let success = try await self.sendKakaoDataToServer(
                    kakaoAuthResCode: token.accessToken,
                    targetLanguage: "ko",
                    isMentor: false
                )
                await MainActor.run {
                    if success {
                        self.isLoggedIn = true
                        completion(.success(true))
                    } else {
                        completion(.failure(NSError(domain: "KakaoLogin", code: -2, userInfo: [NSLocalizedDescriptionKey: "서버 로그인 실패"])))
                    }
                }
            } catch {
                await MainActor.run {
                    print("=== 카카오 서버 전송 에러 ===")
                    print("Error: \(error)")
                    print("========================")
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func sendKakaoDataToServer(kakaoAuthResCode: String, targetLanguage: String, isMentor: Bool) async throws -> Bool {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIKakaoLoginURL") as? String else {
            print("URL이 존재하지 않습니다.")
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "kakaoAuthResCode": kakaoAuthResCode,
            "targetLanguage": targetLanguage,
            "isMentor": isMentor
        ]
        
        print("=== 카카오 로그인 요청 ===")
        print("URL: \(endPoint)")
        print("Parameters: \(parameters)")
        print("=====================")
        
        let dataResponse = await AF.request(
            endPoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .serializingData()
        .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(KakaoLoginResponse.self, from: data)
                print("=== 카카오 로그인 성공 ===")
                print("Response: \(response)")
                print("=====================")
                
                // 토큰 저장
                UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                UserDefaults.standard.set(response.userName, forKey: "userName")
                
                return true
            } catch {
                print("=== 카카오 디코딩 에러 ===")
                print("Error: \(error)")
                if let rawJSON = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(rawJSON)")
                }
                print("=====================")
                throw UserAPIError.decodingError(description: "카카오 로그인 디코딩 실패: \(error)")
            }
            
        case .failure(let error):
            print("=== 카카오 서버 에러 ===")
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("Server Response: \(rawString)")
            }
            
            if let httpResponse = dataResponse.response {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            print("Error: \(error)")
            print("=====================")
            throw UserAPIError.serverError(message: "카카오 로그인 서버 에러")
        }
    }
    
    func logout() {
        UserApi.shared.logout { [weak self] error in
            if let error = error {
                print("카카오 로그아웃 실패: \(error)")
            } else {
                print("카카오 로그아웃 성공")
                UserDefaults.standard.removeObject(forKey: "accessToken")
                UserDefaults.standard.removeObject(forKey: "refreshToken")
                UserDefaults.standard.removeObject(forKey: "userName")
                self?.isLoggedIn = false
            }
        }
    }
}
