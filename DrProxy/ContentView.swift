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
        .toolbar(content: {
            Text(jobState.isRunning ? "Running" : "Not running")
                .foregroundColor(.secondary)
            Button(action: stop) { Image(systemName: "stop.fill") }
                .help("Stop")
                .environment(\.isEnabled, jobState.isRunning)
            Button(action: start) { Image(systemName: "play.fill") }
                .help("Start")
                .environment(\.isEnabled, !jobState.isRunning)
        })
        .navigationSubtitle(subtitle)
        .padding()
        .frame(minHeight: 200)
        .alert(loader.error?.error.localizedDescription ?? "Error", isPresented: $loader.hasError, actions: {}, message: {
            if let error = loader.error?.error {
                ErrorView(error: error)
            }
        })
    }

    private var subtitle: String {
        [
            loader.loadedPath,
            loader.hasChanges ? "Edited" : nil
        ].compactMap { $0 }.joined(separator: " — ")
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
