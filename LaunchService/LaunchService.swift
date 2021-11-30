//
//  LaunchService.swift
//  LaunchService
//
//  Created by Gareth Redman on 30/11/21.
//

import Foundation
import ServiceManagement

import Services

private let pathKey = "PATH"
private let path = "/usr/local/bin"

class LaunchService: NSObject, LaunchServiceProtocol {
    func getPID(label: String, withReply reply: @escaping (NSError?, Int) -> Void) {
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
        process.arguments = ["-c", "launchctl list \(label)"]
        process.standardOutput = stdout
        process.standardError = stderr
        var data: Data?
        do {
            try process.run()
            process.waitUntilExit()
            data = try stdout.fileHandleForReading.readToEnd()
        } catch {
            reply(error as NSError, -1)
            return
        }

        guard process.terminationStatus == 0, let data = data, let string = String(data: data, encoding: .utf8) else {
            let data = try? stderr.fileHandleForReading.readToEnd()
            let output = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""

            let error = NSError(domain: "computer.gareth.DrProxy.HashService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "cntlm failed",
                "termination status": "\(process.terminationStatus)",
                "stderr": output
            ])
            reply(error, -1)
            return
        }

        let regex = try! NSRegularExpression(pattern: #"^\s+"PID" = (\d+);$"#, options: [])
        var pid = -1
        string.enumerateLines { line, _ in
            guard let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) else {
                return
            }

            let string = String(line[Range(match.range(at: 1), in: line)!])
            pid = Int(string) ?? pid
        }
        reply(nil, pid)
    }
}
