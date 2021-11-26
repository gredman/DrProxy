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
    func computeHash(domain: String, username: String, password: String, withReply reply: @escaping (NSError?, PasswordHash?) -> Void)
}

private let pathKey = "PATH"
private let path = "/usr/local/bin"

class HashService: NSObject, HashServiceProtocol {
    func computeHash(domain: String, username: String, password: String, withReply reply: @escaping (NSError?, PasswordHash?) -> Void) {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
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
        process.standardOutput = stdout
        process.standardError = stderr
        var data: Data?
        do {
            try process.run()
            process.waitUntilExit()
            data = try stdout.fileHandleForReading.readToEnd()
        } catch {
            reply(error as NSError, nil)
        }

        guard process.terminationStatus == 0, let data = data, let string = String(data: data, encoding: .utf8) else {
            let data = try? stderr.fileHandleForReading.readToEnd()
            let output = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

            let error = NSError(domain: "computer.gareth.DrProxy.HashService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "cntlm failed",
                "termination status": "\(process.terminationStatus)",
                "stderr": output
            ])
            reply(error, nil)
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
        reply(nil, hash)
    }
}
