//
//  ConfigDocument.swift
//  DrProxy
//
//  Created by Gareth Redman on 29/11/21.
//

import Foundation
import SwiftUI

struct IdentifiedError: Identifiable, Equatable {
    let error: Error
    let id = UUID()

    static func == (lhs: IdentifiedError, rhs: IdentifiedError) -> Bool {
        lhs.id == rhs.id
    }
}

struct ConfigDocument {
    private var savedFile: ConfigFile?

    private var bookmarkData: Data? {
        get {
            UserDefaults.standard.data(forKey: AppStorage.configBookmarkKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppStorage.configBookmarkKey)
        }
    }

    var file = ConfigFile()
    var error: IdentifiedError?

    var isLoaded: Bool {
        savedFile != nil
    }

    var hasChanges: Bool {
        isLoaded && savedFile != file
    }

    var hasError: Bool {
        get { error != nil }
        set {
            assert(!newValue)
            error = nil
        }
    }

    mutating func load() {
        guard let bookmarkData = bookmarkData else {
            return
        }

        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
            if isStale {
                self.bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            }

            file = try ConfigFile(contentsOf: url)
            savedFile = file
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }

    mutating func load(path: String) {
        do {
            let url = URL(fileURLWithPath: path)
            file = try ConfigFile(contentsOf: url)
            bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            savedFile = file
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }

    mutating func save() {
        do  {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData!, bookmarkDataIsStale: &isStale)
            if isStale {
                bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            }
            try file.write(to: url)
            savedFile = file
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }
}
