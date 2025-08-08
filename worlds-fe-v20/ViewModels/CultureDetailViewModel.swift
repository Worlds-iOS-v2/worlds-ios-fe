//
//  CultureDetailViewModel.swift
//  worlds-fe-v20
//
//  Created by soy on 7/29/25.
//

import SwiftUI

final class CultureDetailViewModel: ObservableObject {
    let dummyGovernmentData = [
        GovernmentProgram(
            borough: "서초구",
            title: "다문화 가족 지원 프로그램",
            image: "https://example.com/image.jpg",
            url: "https://example.com/program",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            programPeriod: "2025-02-01 ~ 2025-03-31",
            target: "다문화가족",
            personnel: "50명",
            programDetail: "이 프로그램은 다문화 가족의 정착을 지원하기 위한 교육 및 상담 프로그램입니다.",
            location: "서초구 가족센터"
        ),
        GovernmentProgram(
            borough: "서초구",
            title: "다문화 가족 지원 프로그램",
            image: "https://example.com/image.jpg",
            url: "https://example.com/program",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            programPeriod: "2025-02-01 ~ 2025-03-31",
            target: "다문화가족",
            personnel: "50명",
            programDetail: "이 프로그램은 다문화 가족의 정착을 지원하기 위한 교육 및 상담 프로그램입니다.",
            location: "서초구 가족센터"
        ),
        GovernmentProgram(
            borough: "서초구",
            title: "다문화 가족 지원 프로그램",
            image: "https://example.com/image.jpg",
            url: "https://example.com/program",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            programPeriod: "2025-02-01 ~ 2025-03-31",
            target: "다문화가족",
            personnel: "50명",
            programDetail: "이 프로그램은 다문화 가족의 정착을 지원하기 위한 교육 및 상담 프로그램입니다.",
            location: "서초구 가족센터"
        )
    ]

    let dummyKoreanData = [
        KoreanProgram(
            borough: "성동구",
            title: "한국어 교육 프로그램",
            image: "https://example.com/image.jpg",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            programPeriod: "2025-02-01 ~ 2025-03-31",
            location: "성동구 가족센터",
            url: "https://example.com/program"
        ),
        KoreanProgram(
            borough: "성동구",
            title: "한국어 교육 프로그램",
            image: "https://example.com/image.jpg",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            programPeriod: "2025-02-01 ~ 2025-03-31",
            location: "성동구 가족센터",
            url: "https://example.com/program"
        ),
        KoreanProgram(
            borough: "성동구",
            title: "한국어 교육 프로그램",
            image: "https://example.com/image.jpg",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            programPeriod: "2025-02-01 ~ 2025-03-31",
            location: "성동구 가족센터",
            url: "https://example.com/program"
        )
    ]

    let dummyEventData = [
        EventProgram(
            borough: "서초구",
            title: "다문화 가족 지원 프로그램",
            image: "https://example.com/image.jpg",
            programPeriod: "2025-01-01 ~ 2025-01-31",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            target: "다문화가족",
            price: "무료",
            contact: "02-123-4567",
            location: "서초구 가족센터",
            url: "https://example.com/program"
        ),
        EventProgram(
            borough: "서초구",
            title: "다문화 가족 지원 프로그램",
            image: "https://example.com/image.jpg",
            programPeriod: "2025-01-01 ~ 2025-01-31",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            target: "다문화가족",
            price: "무료",
            contact: "02-123-4567",
            location: "서초구 가족센터",
            url: "https://example.com/program"
        ),
        EventProgram(
            borough: "서초구",
            title: "다문화 가족 지원 프로그램",
            image: "https://example.com/image.jpg",
            programPeriod: "2025-01-01 ~ 2025-01-31",
            applicationPeriod: "2025-01-01 ~ 2025-01-31",
            target: "다문화가족",
            price: "무료",
            contact: "02-123-4567",
            location: "서초구 가족센터",
            url: "https://example.com/program"
        ),
    ]
}
