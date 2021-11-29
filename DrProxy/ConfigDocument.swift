//
//  ConfigDocument.swift
//  DrProxy
//
//  Created by Gareth Redman on 29/11/21.
//

import Foundation

struct IdentifiedError: Identifiable, Equatable {
    let error: Error
    let id = UUID()

    static func == (lhs: IdentifiedError, rhs: IdentifiedError) -> Bool {
        lhs.id == rhs.id
    }
}

struct ConfigDocument {
    private var path: String?
    private var savedFile: ConfigFile?

    var file = ConfigFile()
    var error: IdentifiedError?

    var hasChanges: Bool {
        savedFile != file
    }

    var hasError: Bool {
        get { error != nil }
        set {
            assert(!newValue)
            error = nil
        }
    }

    mutating func load(path: String) async {
        do {
            try await _load(path: path)
            error = nil
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }

    mutating func save() async {
        guard path != nil else { return }
        do {
            try await _save()
            error = nil
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }

    private mutating func _load(path: String) async throws {
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
        self.path = path
    }

    private mutating func _save() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let url = URL(fileURLWithPath: path!)
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
