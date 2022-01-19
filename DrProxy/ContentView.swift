//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var loader: ConfigLoader
    @ObservedObject var jobState: JobState

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
        .frame(minHeight: 200)
        .alert(loader.error?.error.localizedDescription ?? "Error", isPresented: $loader.hasError, actions: {}, message: {
            if let error = loader.error?.error {
                ErrorView(error: error)
            }
        })
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
        if case .error = jobState.status {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .labelStyle(.titleAndIcon)
        } else {
            toolbarButtons(status: jobState.status)
        }
    }

    @ViewBuilder
    private func toolbarButtons(status: JobState.Status) -> some View {
        Text(status.description)
            .foregroundColor(.secondary)
        Button(action: stop) { Image(systemName: "stop.fill") }
            .help("Stop")
            .environment(\.isEnabled, status.isRunning)
        Button(action: start) { Image(systemName: "play.fill") }
            .help("Start")
            .environment(\.isEnabled, !status.isRunning)
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
}
