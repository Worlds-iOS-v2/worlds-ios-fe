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
    
    // 댓글 또는 대댓글 작성
    func postComment(content: String, questionId: Int, parentId: Int? = nil) async throws -> Bool {
        let headers = try getAuthHeaders()

        // parentId가 있을 경우만 포함되도록 params 구성
        var params: [String: Any] = ["content": content]
        if let parentId = parentId {
            params["parentId"] = parentId
        }

        let response = try await AF.request(
            "\(baseURL)/comment/question/\(questionId)",
            method: .post,
            parameters: params,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .serializingData()
        .response

        return response.error == nil
    }
    
    // 댓글 조회
    func fetchComments(for questionId: Int) async throws -> [Comment] {
        let headers = try getAuthHeaders()

        let response = try await AF.request(
            "\(baseURL)/comment/question/\(questionId)",
            headers: headers
        )
        .validate()
        .serializingDecodable([Comment].self)
        .value

        return response
    }
    
    // 댓글 삭제
    func deleteComment(commentId: Int) async throws -> Bool {
        let headers = try getAuthHeaders()

        let response = try await AF.request(
            "\(baseURL)/comment/\(commentId)",
            method: .delete,
            headers: headers
        )
        .validate()
        .serializingData()
        .response

        return response.error == nil
    }
    
    // 댓글 좋아요 토글
    func toggleCommentLike(commentId: Int) async throws -> CommentLike {
        let headers = try getAuthHeaders()

        // 먼저 POST 요청 (좋아요 시도)
        let postResponse = try await AF.request(
            "\(baseURL)/comment/like/\(commentId)",
            method: .post,
            headers: headers
        )
        .validate()
        .serializingData()
        .response

        if postResponse.error == nil {
            // 좋아요 성공 → count 다시 조회
            let count = try await fetchLikeCount(commentId: commentId)
            return CommentLike(id: commentId, count: count, isLiked: true)
        } else {
            // 이미 좋아요한 상태일 경우 → DELETE로 취소 시도
            let deleteResponse = try await AF.request(
                "\(baseURL)/comment/like/\(commentId)",
                method: .delete,
                headers: headers
            )
            .validate()
            .serializingData()
            .response

            if deleteResponse.error == nil {
                // 좋아요 취소 성공 → count 다시 조회
                let count = try await fetchLikeCount(commentId: commentId)
                return CommentLike(id: commentId, count: count, isLiked: false)
            } else {
                // POST 실패 + DELETE 실패 → 에러 반환
                throw deleteResponse.error!
            }
        }
    }
    
    // 댓글 좋아요 수 + isLiked 여부 조회(백엔드를 따로따로 만들어서 둘을 합쳐 쓰기 위한 함수)
    // 1. fetchLikeCount()를 호출해서 해당 댓글에 총 몇 개의 좋아요가 있는지 가져오고
    // 2. fetchIsLiked()를 호출해서 내가 좋아요를 눌렀는지 서버에서 확인한 뒤
    // 3. 그 정보를 바탕으로 CommentLike 구조체 생성해서 반환
    func fetchCommentLike(commentId: Int) async throws -> CommentLike {
        let headers = try getAuthHeaders()

        let count = try await fetchLikeCount(commentId: commentId)
        let isLiked = try await fetchIsLiked(commentId: commentId)

        return CommentLike(id: commentId, count: count, isLiked: isLiked)
    }
    
    // 좋아요 수
    func fetchLikeCount(commentId: Int) async throws -> Int {
        let headers = try getAuthHeaders()

        let count = try await AF.request(
            "\(baseURL)/comment/like/\(commentId)/count",
            headers: headers
        )
        .validate()
        .serializingDecodable(Int.self)
        .value

        return count
    }
    
    // 유저가 좋아요를 눌렀는지 여부
    func fetchIsLiked(commentId: Int) async throws -> Bool {
        let headers = try getAuthHeaders()

        let response = try await AF.request(
            "\(baseURL)/comment/like/\(commentId)/isLiked",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(Bool.self)
        .value

        return response
    }
}
