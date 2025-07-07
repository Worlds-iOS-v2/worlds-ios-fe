//
//  APIService.swift
//  worlds-v20
//
//  Created by 이서하 on 7/4/25.
//

import Foundation
import Alamofire
import UIKit

class APIService {
    static let shared = APIService()
    let baseURL = "http://localhost:3000"
    enum APIError: Error {
        case missingToken
    }
    //JWT 토큰 가져오기
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "jwt_token")
    }
    //토큰이 필요한 API 호출을 위한 HTTP헤더 생성
    private func getAuthHeaders() throws -> HTTPHeaders {
        guard let token = getToken() else {
            throw APIError.missingToken
        }
        return ["Authorization": "Bearer \(token)"] //이걸 헤더에 실어보내는 것
    }
    
    //로긘 횐가입
    //..........
    
    //질문 목록 조회
    func fetchQuestions() async throws -> [QuestionList] {
            let headers = try getAuthHeaders()

            let response = try await AF.request("\(baseURL)/questions", headers: headers)
                .serializingDecodable([QuestionList].self)
                .value
                
            return response
        }
    
    //질문 상세
    func fetchQuestionDetail(questionId: Int) async throws -> QuestionDetail {
            let headers = try getAuthHeaders()

            let response = try await AF.request("\(baseURL)/questions/\(questionId)", headers: headers)
                .serializingDecodable(QuestionDetail.self)
                .value
            
            return response
        }
    
    //질문 생성
    func createQuestion(_ request: CreateQuestion) async throws {
        let headers = try getAuthHeaders()
        
        let url = "\(baseURL)/questions"
        //        let data: [String: Any] = ["title": title, "content": content]
        
        let response = try await AF.request(
            url,
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .value
    }

    
    //질문 삭제
    func deleteQuestion(questionId: Int) async throws -> Bool {
            let headers = try getAuthHeaders()

            let response = try await AF.request("\(baseURL)/questions/\(questionId)", method: .delete,
                                                headers: headers)
                .validate()
                .serializingData()
                .response
        
            print("삭제 완료: \(response)")
            return response.error == nil
            
        }
    
    
    
}
