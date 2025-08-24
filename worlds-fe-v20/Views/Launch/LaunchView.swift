//
//  LaunchView.swift
//  worlds-fe-v20
//
//  Created by seohuibaek on 8/21/25.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .frame(width: 200, height: 200)
        }
        .padding()
    }
}

#Preview {
    LaunchView()
}
