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
    func stop(label: String, withReply reply: @escaping (NSError?) -> Void)
    func start(label: String, withReply reply: @escaping (NSError?) -> Void)
    func restart(label: String, withReply reply: @escaping (NSError?) -> Void)
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

    func stop(label: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            stop(label: label) { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            }
        }
    }

    func start(label: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            start(label: label) { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            }
        }
    }

    func restart(label: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            restart(label: label) { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            }
        }
    }
}
