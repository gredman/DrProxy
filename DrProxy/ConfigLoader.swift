//
//  ConfigLoader.swift
//  DrProxy
//
//  Created by Gareth Redman on 29/11/21.
//

import Foundation
import SwiftUI

import os

private let log = Logger(subsystem: Bundle.main.bundleIdentifier!, category: #fileID)

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
            Task { await updateHasChanges() }
        }
    }
    @Published var error: IdentifiedError? {
        didSet {
            Task { await updateHasError() }
        }
    }

    @Published var isLoaded = false
    @Published var hasBookmark = false
    @Published var hasChanges = false
    @Published var hasError = false
    @Published var loadedPath: String?

    private var savedFile: ConfigFile? {
        didSet {
            Task {
                await updateIsLoaded()
                await updateHasChanges()
            }
        }
    }

    private var bookmarkData: Data? {
        get {
            UserDefaults.standard.data(forKey: AppStorage.configBookmarkKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppStorage.configBookmarkKey)
            Task { await updateHasBookmark() }
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
        await updateHasBookmark()
        guard let bookmarkData = bookmarkData else {
            return
        }

        log.debug("loading config file from bookmark data")
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
            if isStale {
                log.warning("bookmark data is stale on load -- updating it")
                self.bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            }
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
            bookmarkData = try url.bookmarkData(options: .minimalBookmark)
        } catch {
            await setError(error)
        }
    }

    func save() async {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData!, bookmarkDataIsStale: &isStale)
            if isStale {
                log.warning("bookmark data is stale on load -- updating it")
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

    @MainActor
    private func updateIsLoaded() {
        isLoaded = savedFile != nil
    }

    @MainActor
    private func updateHasChanges() {
        hasChanges = isLoaded && savedFile != file
    }

    @MainActor
    private func updateHasBookmark() {
        hasBookmark = bookmarkData != nil
    }

    @MainActor
    private func updateHasError() {
        hasError = error != nil
    }
}

extension ConfigLoader: NSFilePresenter {
    var presentedItemURL: URL? {
        guard let bookmarkData = bookmarkData else { return nil}
        var isStale = false
        let url = try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)

        if isStale, let url = url {
            log.warning("bookmark data is stale in file presenter getter -- updating it")
            do {
                self.bookmarkData = try url.bookmarkData(options: .minimalBookmark)
            } catch {
                log.error("couldn't get updated bookmark data")
            }
        }

        return url
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
