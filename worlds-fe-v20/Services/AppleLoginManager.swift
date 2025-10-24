//
//  AppleLoginManager.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 9/8/25.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import Alamofire

// MARK: - 애플 로그인 매니저
class AppleLoginManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published var isLoggedIn = false
    private var loginCompletion: ((Result<Bool, Error>) -> Void)?
    
    func loginWithApple(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.loginCompletion = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                loginCompletion?(.failure(NSError(domain: "AppleLogin", code: -1, userInfo: [NSLocalizedDescriptionKey: "토큰을 가져올 수 없습니다."])))
                return
            }
            
            // 디바이스 언어 가져오기
            var deviceLanguage = "en"
            
            if let preferredLanguage = Locale.preferredLanguages.first {
                let locale = Locale(identifier: preferredLanguage)
                deviceLanguage = locale.languageCode ?? "en"
            }
            
            // 이메일과 이름 처리 (최초에만 제공되므로 저장)
            var email = appleIDCredential.email
            var givenName = appleIDCredential.fullName?.givenName
            var familyName = appleIDCredential.fullName?.familyName
            
            // 최초 로그인인 경우 (값이 있으면) 저장
            if let userEmail = email {
                UserDefaults.standard.set(userEmail, forKey: "appleUserEmail")
            }
            if let name = givenName {
                UserDefaults.standard.set(name, forKey: "appleGivenName")
            }
            if let family = familyName {
                UserDefaults.standard.set(family, forKey: "appleFamilyName")
            }
            
            // nil이면 저장된 값 사용 (두 번째 로그인부터)
            if email == nil {
                email = UserDefaults.standard.string(forKey: "appleUserEmail")
            }
            if givenName == nil {
                givenName = UserDefaults.standard.string(forKey: "appleGivenName")
            }
            if familyName == nil {
                familyName = UserDefaults.standard.string(forKey: "appleFamilyName")
            }
            
            print("=== Apple Login - 백엔드 전송 데이터 ===")
            print("User Identifier (oauthId): \(appleIDCredential.user)")
            print("ID Token: \(idTokenString)")
            print("Email: \(email ?? "nil")")
            print("Given Name: \(givenName ?? "nil")")
            print("Family Name: \(familyName ?? "nil")")
            print("Device Language: \(deviceLanguage)")
            print("=======================================")
            
            // 서버에 애플 로그인 데이터 전송
            Task {
                do {
                    let success = try await self.sendAppleDataToServer(
                        oauthId: appleIDCredential.user,
                        idToken: idTokenString,
                        email: appleIDCredential.email ?? "sample@sample.com",
                        givenName: appleIDCredential.fullName?.givenName ?? "sampleName",
                        familyName: appleIDCredential.fullName?.familyName ?? "sampleName",
                        targetLanguage: deviceLanguage
                    )
                    
                    await MainActor.run {
                        if success {
                            self.isLoggedIn = true
                            self.loginCompletion?(.success(true))
                        } else {
                            self.loginCompletion?(.failure(NSError(domain: "AppleLogin", code: -2, userInfo: [NSLocalizedDescriptionKey: "서버 로그인 실패"])))
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.loginCompletion?(.failure(error))
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("=== Apple Login 에러 ===")
        print("Error: \(error.localizedDescription)")
        print("=====================")
        loginCompletion?(.failure(error))
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
    
    private func sendAppleDataToServer(oauthId: String, idToken: String, email: String, givenName: String, familyName: String, targetLanguage: String) async throws -> Bool {
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIAppleLoginURL") as? String else {
            print("URL이 존재하지 않습니다.")
            throw UserAPIError.invalidEndPoint
        }
        
        let parameters: [String: Any] = [
            "oauthId": oauthId,
            "idToken": idToken,
            "email": email,
            "givenName": givenName,
            "familyName": familyName,
            "targetLanguage": targetLanguage
        ]
        
        print("=== 애플 로그인 요청 ===")
        print("URL: \(endPoint)")
        print("Parameters: \(parameters)")
        print("=====================")
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .serializingData()
            .response
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(AppleLoginResponse.self, from: data)
                print("=== 애플 로그인 성공 ===")
                print("Response: \(response)")
                print("=================")
                
                // 토큰 저장
                UserDefaults.standard.set(response.accessToken, forKey: "accessToken")
                UserDefaults.standard.set(response.refreshToken, forKey: "refreshToken")
                UserDefaults.standard.set(response.username, forKey: "userName")
                
                return true
            } catch {
                print("=== 애플 디코딩 에러 ===")
                print("Error: \(error)")
                if let rawJSON = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(rawJSON)")
                }
                print("==================")
                throw UserAPIError.decodingError(description: "애플 로그인 디코딩 실패: \(error)")
            }
            
        case .failure(let error):
            print("=== 애플 서버 에러 ===")
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("Server Response: \(rawString)")
            }
            
            if let httpResponse = dataResponse.response {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            print("Error: \(error)")
            print("==================")
            throw UserAPIError.serverError(message: "애플 로그인 서버 에러")
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "userName")
        self.isLoggedIn = false
        print("애플 로그아웃 성공")
    }
}
