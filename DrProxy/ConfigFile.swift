//
//  ConfigFile.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import Foundation
import SwiftUI

struct ConfigFile {
    private var lines: [Line]

    private struct Line: Identifiable {
        let id: UUID
        var content: Content

        enum Content {
            case comment(text: String)
            case option(name: String, space: String, value: String)
        }

        static func comment(text: String) -> Line {
            Line(id: UUID(), content: .comment(text: text))
        }

        static func option(name: String, space: String, value: String) -> Line {
            Line(id: UUID(), content: .option(name: name, space: space, value: value))
        }

        var isOption: Bool {
            if case .option = content {
                return true
            } else {
                return false
            }
        }
    }

    init() {
        self.lines = []
    }

    init(string: String) throws {
        let regex = try! NSRegularExpression(pattern: #"^(\w+)(\s+)(.+)$"#, options: [])
        var lines = [Line]()
        string.enumerateLines(invoking: { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.starts(with: "#") {
                lines.append(.comment(text: line))
            } else if let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.count)) {
                let name = String(trimmed[Range(match.range(at: 1), in: trimmed)!])
                let space = String(trimmed[Range(match.range(at: 2), in: trimmed)!])
                let value = String(trimmed[Range(match.range(at: 3), in: trimmed)!])
                lines.append(Line.option(name: name, space: space, value: value))
            } else {
                lines.append(.comment(text: line))
            }
        })
        self.lines = lines
    }

    var username: String {
        get { self["Username"] }
        set { self["Username"] = newValue }
    }

    var domain: String {
        get { self["Domain"] }
        set { self["Domain"] = newValue }
    }

    var passLM: String {
        get { self["PassLM"] }
        set { self["PassLM"] = newValue }
    }

    var passNT: String {
        get { self["PassNT"] }
        set { self["PassNT"] = newValue }
    }

    var passNTLMv2: String {
        get { self["PassNTLMv2"] }
        set { self["PassNTLMv2"] = newValue }
    }

    var proxy: String {
        get { self["Proxy"] }
        set { self["Proxy"] = newValue }
    }

    var noProxy: String {
        get { self["NoProxy"] }
        set { self["NoProxy"] = newValue }
    }

    var listen: String {
        get { self["Listen"] }
        set { self["Listen"] = newValue }
    }

    var gateway: String {
        get { self["Gateway"] }
        set { self["Gateway"] = newValue }
    }

    subscript(name: String) -> String {
        get {
            for line in lines {
                if case let .option(name: n, space: _, value: value) = line.content, n == name {
                    return value
                }
            }
            return ""
        }
        set {
            var index: Int? = nil
            var space: String? = nil
            for i in lines.indices {
                if case let .option(name: n, space: s, value: _) = lines[i].content, n == name {
                    index = i
                    space = s
                    break
                }
            }
            if let index = index {
                var updated = lines[index]
                updated.content = .option(name: name, space: space ?? "\n", value: newValue)
                lines[index] = updated
            } else {
                lines.append(.option(name: name, space: "\t", value: newValue))
            }
        }
    }

    var string: String {
        var result: [String] = []
        for line in lines {
            switch line.content {
            case let .comment(text: text):
                result.append(text)
            case let .option(name: name, space: space, value: value):
                result.append("\(name)\(space)\(value)")
            }
        }
        return result.joined(separator: "\n")
    }
}
