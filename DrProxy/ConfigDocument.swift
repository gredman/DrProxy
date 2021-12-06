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

class ConfigDocument: NSObject, ObservableObject {
    @Published var file = ConfigFile() {
        didSet {
            updateHasChanges()
        }
    }
    @Published var error: IdentifiedError? {
        didSet {
            updateHasError()
        }
    }

    @Published var isLoaded = false
    @Published var hasChanges = false
    @Published var hasError = false

    private var savedFile: ConfigFile? {
        didSet {
            updateIsLoaded()
            updateHasChanges()
        }
    }

    private func updateIsLoaded() {
        isLoaded = savedFile != nil
    }

    private func updateHasChanges() {
        hasChanges = isLoaded && savedFile != file
    }

    private func updateHasError() {
        hasError = error != nil
    }

    private var bookmarkData: Data? {
        get {
            UserDefaults.standard.data(forKey: AppStorage.configBookmarkKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppStorage.configBookmarkKey)
        }
    }

    override init() {
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    func load() {
        guard let bookmarkData = bookmarkData else {
            return
        }

        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
            load(url: url)
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }

    func load(path: String) {
        load(url: URL(fileURLWithPath: path))
    }

    func load(url: URL) {
        var error: NSError?
        let coordinator = NSFileCoordinator(filePresenter: self)
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { url in
            do {
                self.file = try ConfigFile(contentsOf: url)
            } catch {
                self.error = IdentifiedError(error: error)
            }
        }

        do {
            bookmarkData = try url.bookmarkData(options: .minimalBookmark)
        } catch {
            self.error = IdentifiedError(error: error)
        }

        savedFile = file
    }

    func save() {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData!, bookmarkDataIsStale: &isStale)
            if isStale {
                bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            }
            var error: NSError?
            let coordinator = NSFileCoordinator(filePresenter: self)
            coordinator.coordinate(writingItemAt: url, options: [], error: &error) { url in
                do {
                    try self.file.write(to: url)
                } catch {
                    self.error = IdentifiedError(error: error)
                }
            }
            savedFile = file
        } catch {
            self.error = IdentifiedError(error: error)
        }
    }
}

extension ConfigDocument: NSFilePresenter {
    var presentedItemURL: URL? {
        guard let bookmarkData = bookmarkData else { return nil}
        var isStale = false
        return try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
    }

    var presentedItemOperationQueue: OperationQueue {
        .main
    }

    func presentedItemDidChange() {
        load()
    }
}
