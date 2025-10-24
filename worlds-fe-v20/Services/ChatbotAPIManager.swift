//
//  ChatbotAPIManager.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 10/17/25.
//

import Foundation
import Alamofire

class ChatbotAPIManager {
    static let shared = ChatbotAPIManager()
    
    private init() {}
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken")
    }
    
    private func getAuthHeaders() -> HTTPHeaders? {
        guard let token = getToken() else {
            return nil
        }
        return ["Authorization": "Bearer \(token)"]
    }
    
    func sendQuestion(question: String) async throws -> String {
        guard let token = UserDefaults.standard.string(forKey: "accessToken") else {
            print("토큰 값이 유효하지 않습니다.")
            throw UserAPIError.invalidToken
        }
        
        guard let endPoint = Bundle.main.object(forInfoDictionaryKey: "APIChatbotURL") as? String else {
            throw UserAPIError.invalidEndPoint
        }
        
        print("API 엔드포인트: \(endPoint)")
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let parameters: [String: Any] = [
            "question": question
        ]
        
        print("요청 파라미터: \(parameters)")
        
        let dataResponse = await AF.request(endPoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .serializingData()
            .response
        
        print("응답 결과: \(dataResponse.result)")
        
        switch dataResponse.result {
        case .success(let data):
            do {
                let response = try JSONDecoder().decode(ChatbotResponse.self, from: data)
                print("챗봇 응답: \(response)")
                
                if response.statusCode == 200 {
                    return response.answer
                } else {
                    throw UserAPIError.serverError(message: response.message)
                }
            } catch {
                print("디코딩 에러: \(error.localizedDescription)")
                
                if let rawJSON = String(data: data, encoding: .utf8) {
                    print("원본 JSON 응답:\n\(rawJSON)")
                }
                
                throw UserAPIError.decodingError(description: "디코딩 실패: \(error)")
            }
            
        case .failure:
            if let rawData = dataResponse.data,
               let rawString = String(data: rawData, encoding: .utf8) {
                print("챗봇 서버 원본 응답: \(rawString)")
                
                // 서버 에러 응답 파싱 시도
                do {
                    let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: rawData)
                    print("챗봇 파싱된 에러 응답: \(errorResponse)")
                    
                    let errorMessage = errorResponse.message.first ?? "알 수 없는 에러"
                    throw UserAPIError.serverError(message: errorMessage)
                } catch {
                    throw UserAPIError.serverError(message: "챗봇 서버 응답 파싱 실패")
                }
            } else {
                throw UserAPIError.serverError(message: "챗봇 서버 응답 파싱 실패")
            }
        }
    }
}
