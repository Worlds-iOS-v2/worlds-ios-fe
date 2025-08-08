//
//  dummydata.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/8/25.
//

import Foundation

struct GovernmentDataResponse: Codable {
    let message: String
    let statusCode: Int
    let governmentData: [GovernmentProgram]
    let koreanData: [KoreanProgram]
    let eventData: [EventProgram]
}

struct GovernmentProgram: Codable, Identifiable, CultureDisplayable {
    let id = UUID()
    let borough: String
    let title: String
    let image: String
    let url: String
    let applicationPeriod: String
    let programPeriod: String
    let target: String
    let personnel: String
    let programDetail: String
    let location: String
}

struct KoreanProgram: Codable, Identifiable, CultureDisplayable {
    let id = UUID()
    let borough: String
    let title: String
    let image: String
    let applicationPeriod: String
    let programPeriod: String
    let location: String
    let url: String
}

struct EventProgram: Codable, Identifiable {
    let id = UUID()
    let borough: String
    let title: String
    let image: String
    let programPeriod: String
    let applicationPeriod: String
    let target: String
    let price: String
    let contact: String
    let location: String
    let url: String
}
