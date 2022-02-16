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
        return NSError(domain: "computer.gareth.DrProxy.LaunchService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "cntlm failed",
            "termination status": "\(process.terminationStatus)",
            "stderr": output
        ])
    }

    static func kqueueError(description: String) -> NSError {
        return NSError(domain: "computer.gareth.DrProxy.LaunchService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: description
        ])
    }
}

class LaunchService: NSObject, LaunchServiceProtocol {
    func getPID(label: String, withReply reply: @escaping (NSError?, Int) -> Void) {
        let result = getPID(label: label)
        switch result {
        case let .failure(error):
            reply(error, -1)
        case let .success(pid):
            reply(nil, pid)
        }
    }

    func stop(label: String, withReply reply: @escaping (NSError?) -> Void) {
        reply(stop(label: label))
    }

    func start(label: String, withReply reply: @escaping (NSError?) -> Void) {
        reply(start(label: label))
    }

    private func getPID(label: String) -> Result<Int, NSError> {
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
            return .failure(error as NSError)
        }

        guard process.terminationStatus == 0, let data = data, let string = String(data: data, encoding: .utf8) else {
            let error = NSError.cntlmError(process: process, stderr: stderr)
            return .failure(error)
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
        // TODO: check pid
        return .success(pid)
    }

    private func stop(label: String) -> NSError? {
        // get current pid
        let pidResult = getPID(label: label)
        if case let .failure(error) = pidResult {
            return error
        }
        let pid = try! pidResult.get()

        // launchctl stop
        let process = Process.launchctl(command: "stop", label: label)
        let stderr = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return error as NSError
        }

        guard process.terminationStatus == 0 else {
            return NSError.cntlmError(process: process, stderr: stderr)
        }

        // wait for underlying pid to exit
        if let error = waitForExit(pid: pid) {
            return error
        }

        return nil
    }

    private func start(label: String) -> NSError? {
        let process = Process.launchctl(command: "start", label: label)
        let stderr = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return error as NSError
        }

        guard process.terminationStatus == 0 else {
            return NSError.cntlmError(process: process, stderr: stderr)
        }

        return nil
    }

    private func waitForExit(pid: Int) -> NSError? {
        let kq = kqueue()
        guard kq >= 0 else {
            return NSError.kqueueError(description: "failed to open kqueue")
        }
        defer {
            close(kq)
        }

        var changelist = kevent()
        changelist.ident = UInt(pid)
        changelist.filter = Int16(EVFILT_PROC)
        changelist.flags = UInt16(EV_ADD) | UInt16(EV_ONESHOT)
        changelist.fflags = UInt32(NOTE_EXIT)
        let nchanges: Int32 = 1

        var eventlist = kevent()
        let nevents: Int32 = 1

        var timeout = timespec()
        timeout.tv_sec = 30

        let events = kevent(kq, &changelist, nchanges, &eventlist, nevents, &timeout)
        guard events == 1 else {
            return NSError.kqueueError(description: "kevent timed out waiting for pid \(pid) to exit")
        }

        return nil
    }
}
