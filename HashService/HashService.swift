//
//  HashService.swift
//  HashService
//
//  Created by Gareth Redman on 18/10/21.
//

import Foundation
import ServiceManagement

public typealias PasswordHash = NSDictionary

@objc public protocol HashServiceProtocol {
    func computeHash(domain: String, username: String, password: String, withReply reply: @escaping (PasswordHash?) -> Void)
}

private let pathKey = "PATH"
private let path = "/usr/local/bin"

class HashService: NSObject, HashServiceProtocol {
    func computeHash(domain: String, username: String, password: String, withReply reply: @escaping (PasswordHash?) -> Void) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        var environment = ProcessInfo.processInfo.environment
        if let currentPath = environment[pathKey] {
            environment[pathKey] = currentPath + ":" + path
        } else {
            environment[pathKey] = path
        }
        process.environment = environment
        // TODO: type in password to avoid shell escapes
        process.arguments = ["-c", "cntlm -H -d '\(domain)' -u '\(username)' -p \(password)"]
        process.standardOutput = pipe
        var data: Data?
        do {
            try process.run()
            process.waitUntilExit()
            data = try pipe.fileHandleForReading.readToEnd()
        } catch {
            print("error: \(error)")
            reply(nil)
        }

        guard process.terminationStatus == 0, let data = data, let string = String(data: data, encoding: .utf8) else {
            reply(nil)
            return
        }

        let regex = try! NSRegularExpression(pattern: #"^(\w+)\s+(.+)$"#, options: [])
        let values = NSMutableDictionary()
        string.enumerateLines { line, _ in
            guard let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) else { return }

            let name = String(line[Range(match.range(at: 1), in: line)!])
            let value = String(line[Range(match.range(at: 2), in: line)!])
            values[name] = value
        }
        let hash = PasswordHash(dictionary: values)
        reply(hash)
    }
}
