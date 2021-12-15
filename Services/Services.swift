//
//  Services.swift
//  Services
//
//  Created by Gareth Redman on 30/11/21.
//

import Foundation

public typealias PasswordHash = NSDictionary

@objc public protocol HashServiceProtocol {
    func computeHash(domain: String, username: String, password: String, withReply reply: @escaping (NSError?, PasswordHash?) -> Void)
}

@objc public protocol LaunchServiceProtocol {
    func getPID(label: String, withReply reply: @escaping (NSError?, Int) -> Void)
}

public extension LaunchServiceProtocol {
    func getPID(label: String) async throws -> Int {
        try await withCheckedThrowingContinuation { cont in
            getPID(label: label) { error, pid in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: pid)
                }
            }
        }
    }
}
