//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

private extension Binding where Value == IdentifiedError? {
    var hasValueBinding: Binding<Bool> {
        Binding<Bool>(get: {
            switch wrappedValue {
            case .some: return true
            case .none: return false
            }
        }, set: { newValue in
            assert(!newValue)
            wrappedValue = nil
        })
    }
}

struct ContentView: View, Sendable {
    @ObservedObject var loader: ConfigLoader
    @ObservedObject var jobState: JobState

    @State var presentedError: IdentifiedError?

    var body: some View {
        ZStack {
            mainContentView
                .opacity(loader.hasBookmark ? 1 : 0)
            emptyView
                .opacity(loader.hasBookmark ? 0 : 1)
        }
        .toolbar(content: toolbar)
        .navigationSubtitle(subtitle)
        .padding()
        .frame(minWidth: 600, minHeight: 200)
        .alert(presentedError?.error.localizedDescription ?? "Error", isPresented: $presentedError.hasValueBinding, actions: {}, message: {
            if let error = presentedError?.error {
                ErrorView(error: error)
            }
        })
        .onChange(of: loader.error) { newValue in
            if let error = newValue {
                showError(error)
            }
        }
    }

    private var mainContentView: some View {
        VStack {
            EditorView(loader: loader)
                .environment(\.isEnabled, loader.isLoaded)
            HStack {
                Spacer()
                Button("Open", action: open)
                Button("Save", action: save)
                    .buttonStyle(DefaultButtonStyle())
                    .environment(\.isEnabled, loader.hasChanges)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Text("Hello, my name is Dr. Proxy").font(.headline)
            Text("I hear you are having trouble with CNTLM. Can I take a look at it?")
            Button("Open CNTLM Config", action: open)
                .buttonStyle(.borderedProminent)
        }
    }

    private var subtitle: String {
        [
            loader.loadedPath,
            loader.hasChanges ? "Edited" : nil
        ].compactMap { $0 }.joined(separator: " — ")
    }

    @ViewBuilder
    private func toolbar() -> some View {
        if case let .error(error) = jobState.status {
            Button(action: { showError(error) }) {
                Label("Error", systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .labelStyle(.titleAndIcon)
            }
        } else {
            toolbarButtons(status: jobState.status)
        }
    }

    private func showError(_ error: Error) {
        showError(IdentifiedError(error: error))
    }

    private func showError(_ error: IdentifiedError) {
        presentedError = error
    }

    @ViewBuilder
    private func toolbarButtons(status: JobState.Status) -> some View {
        Text(status.description)
            .foregroundColor(.secondary)
        Group {
            Button(action: restart) { Image(systemName: "arrow.clockwise") }
                .help("Restart")
                .environment(\.isEnabled, status.isRunning)
            Button(action: stop) { Image(systemName: "stop") }
                .help("Stop")
                .environment(\.isEnabled, status.isRunning)
            Button(action: start) { Image(systemName: "play") }
                .help("Start")
                .environment(\.isEnabled, status.isStopped)
        }.symbolVariant(.fill)
    }

    private func open() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: AppStorage.configPathDefault)

        let result = panel.runModal()

        guard result == .OK, let url = panel.url else {
            return
        }

        Task {
            await loader.load(path: url.path)
        }
    }

    private func save() {
        Task {
            await loader.save()
            await jobState.restart()
        }
    }

    private func stop() {
        Task {
            await jobState.stop()
        }
    }

    private func start() {
        Task {
            await jobState.start()
        }
    }

    private func restart() {
        Task {
            await jobState.restart()
        }
    }
}
