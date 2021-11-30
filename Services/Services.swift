//
//  Services.swift
//  Services
//
//  Created by Gareth Redman on 30/11/21.
//

import Foundation

@objc public protocol FileServiceProtocol {
    func readFile(url: URL, withReply reply: @escaping (NSError?, String?) -> Void)
    func writeFile(url: URL, content: String, withReply reply: @escaping (NSError?) -> Void)
}

public typealias PasswordHash = NSDictionary

@objc public protocol HashServiceProtocol {
    func computeHash(domain: String, username: String, password: String, withReply reply: @escaping (NSError?, PasswordHash?) -> Void)
}
