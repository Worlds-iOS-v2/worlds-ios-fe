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
        return UserDefaults.standard.string(forKey: "accessToken")
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
    func createQuestion(title: String, content: String, category: String, images: [Data]? = nil) async throws -> Bool {
        let headers = try getAuthHeaders()
        
        // 이미지가 있으면 multipart/form-data 전송
        if let imagesData = images, !imagesData.isEmpty {
            return try await withCheckedThrowingContinuation { continuation in
                AF.upload(
                    multipartFormData: { multipartFormData in
                        multipartFormData.append(title.data(using: .utf8)!, withName: "title")
                        multipartFormData.append(content.data(using: .utf8)!, withName: "content")
                        multipartFormData.append(category.data(using: .utf8)!, withName: "category")

                        for (index, imageData) in imagesData.enumerated() {
                            multipartFormData.append(imageData,
                                                 withName: "images",
                                                 fileName: "image\(index).jpg",
                                                 mimeType: "image/jpeg")
                        }
                    },
                    to: "\(baseURL)/questions",
                    method: .post,
                    headers: headers
                )
                .validate()
                .response { response in
                    switch response.result {
                    case .success:
                        continuation.resume(returning: true)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } else {
            let params: [String: Any] = [
                "title": title,
                "content": content,
                "category": category
            ]
            
            let response = try await AF.request(
                "\(baseURL)/questions",
                method: .post,
                parameters: params,
                encoding: JSONEncoding.default,
                headers: headers )
            .validate()
            .serializingData()
            .response
            
            return response.error == nil
        }
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
