//
//  ConfigDocument.swift
//  DrProxy
//
//  Created by Gareth Redman on 29/11/21.
//

import Foundation

struct ConfigDocument {
    var savedFile: ConfigFile?
    var file = ConfigFile()

    var hasChanges: Bool {
        savedFile != file
    }

    mutating func load(path: String) async throws {
        let content = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            let url = URL(fileURLWithPath: path)
            NSXPCConnection.fileService.readFile(url: url) { error, content in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let content = content {
                    cont.resume(returning: content)
                } else {
                    fatalError()
                }
            }
        }
        file = try ConfigFile(string: content)
        savedFile = file
    }

    mutating func save(path: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let url = URL(fileURLWithPath: path)
            NSXPCConnection.fileService.writeFile(url: url, content: file.string) { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
        savedFile = file
    }
}
