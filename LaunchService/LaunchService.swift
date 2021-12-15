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

private extension Process {
    static func launchctl(command: String, label: String) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        var environment = ProcessInfo.processInfo.environment
        if let currentPath = environment[pathKey] {
            environment[pathKey] = currentPath + ":" + path
        } else {
            environment[pathKey] = path
        }
        process.environment = environment
        process.arguments = ["-c", "launchctl \(command) \(label)"]
        return process
    }
}

private extension NSError {
    static func cntlmError(process: Process, stderr: Pipe) -> NSError {
        let data = try? stderr.fileHandleForReading.readToEnd()
        let output = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        return NSError(domain: "computer.gareth.DrProxy.HashService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "cntlm failed",
            "termination status": "\(process.terminationStatus)",
            "stderr": output
        ])
    }
}

class LaunchService: NSObject, LaunchServiceProtocol {
    func getPID(label: String, withReply reply: @escaping (NSError?, Int) -> Void) {
        let process = Process.launchctl(command: "list", label: label)
        let stdout = Pipe()
        let stderr = Pipe()
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
            let error = NSError.cntlmError(process: process, stderr: stderr)
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

    func stop(label: String, withReply reply: @escaping (NSError?) -> Void) {
        let process = Process.launchctl(command: "stop", label: label)
        let stderr = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            reply(error as NSError)
            return
        }

        guard process.terminationStatus == 0 else {
            let error = NSError.cntlmError(process: process, stderr: stderr)
            reply(error)
            return
        }

        reply(nil)
    }

    func start(label: String, withReply reply: @escaping (NSError?) -> Void) {
        let process = Process.launchctl(command: "start", label: label)
        let stderr = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            reply(error as NSError)
            return
        }

        guard process.terminationStatus == 0 else {
            let error = NSError.cntlmError(process: process, stderr: stderr)
            reply(error)
            return
        }

        reply(nil)
    }
}
