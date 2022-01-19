//
//  ConfigLoader.swift
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

class ConfigLoader: NSObject, ObservableObject {
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
    @Published var hasBookmark = false
    @Published var hasChanges = false
    @Published var hasError = false
    @Published var loadedPath: String?

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

    private func updateHasBookmark() {
        hasBookmark = bookmarkData != nil
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

    func load() async {
        updateHasBookmark()
        guard let bookmarkData = bookmarkData else {
            return
        }

        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
            await load(url: url)
        } catch {
            await setError(error)
        }
    }

    func load(path: String) async {
        await load(url: URL(fileURLWithPath: path))
    }

    func load(url: URL) async {
        do {
            let coordinator = NSFileCoordinator(filePresenter: self)
            let url = try await coordinator.coordinate(readingItemAt: url)
            let file = try ConfigFile(contentsOf: url)
            await setFile(file)
            await setLoadedPath(url.path)
            try await setBookmarkData(url.bookmarkData(options: .minimalBookmark))
        } catch {
            await setError(error)
        }
    }

    func save() async {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData!, bookmarkDataIsStale: &isStale)
            if isStale {
                bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            }
            let coordinator = NSFileCoordinator(filePresenter: self)
            let url2 = try await coordinator.coordinate(readingItemAt: url)
            try file.write(to: url2)
            savedFile = file
        } catch {
            await setError(error)
        }
    }

    @MainActor
    func setBookmarkData(_ data: Data) {
        self.bookmarkData = data
    }

    @MainActor
    func setFile(_ file: ConfigFile) {
        self.file = file
        self.savedFile = file
        self.error = nil
    }

    @MainActor
    func setError(_ error: Error) {
        self.error = IdentifiedError(error: error)
    }

    @MainActor
    func setLoadedPath(_ path: String) {
        self.loadedPath = path
    }
}

extension ConfigLoader: NSFilePresenter {
    var presentedItemURL: URL? {
        guard let bookmarkData = bookmarkData else { return nil}
        var isStale = false
        return try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
    }

    var presentedItemOperationQueue: OperationQueue {
        .main
    }

    func presentedItemDidChange() {
        Task {
            await load()
        }
    }
}

private extension NSFileCoordinator {
    func coordinate(readingItemAt url: URL, options: ReadingOptions = []) async throws -> URL {
        var error: NSError?
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            coordinate(readingItemAt: url, options: options, error: &error) { url in
                cont.resume(returning: url)
            }
            if let error = error {
                cont.resume(throwing: error)
            }
        }
    }

    func coordinate(writingItemAt url: URL, options: WritingOptions = [])async throws -> URL  {
        var error: NSError?
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            coordinate(writingItemAt: url, options: options, error: &error) { url in
                cont.resume(returning: url)
            }
            if let error = error {
                cont.resume(throwing: error)
            }
        }
    }
}
