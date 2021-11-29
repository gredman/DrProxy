//
//  ErrorView.swift
//  DrProxy
//
//  Created by Gareth Redman on 29/11/21.
//

import SwiftUI

struct ErrorView: View {
    let error: Error

    var body: some View {
        let userInfo = (error as NSError).userInfo
        let text = userInfo.keys.map { key in
            "\(key): \(userInfo[key] ?? "–")"
        }.joined(separator: "\n")
        Text(text)
    }
}
