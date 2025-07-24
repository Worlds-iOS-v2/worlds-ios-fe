//
//  UIExtensions.swift
//  worlds-fe-v20
//
//  Created by 이서하 on 7/24/25.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
