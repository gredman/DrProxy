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
            Text(jobState.pid != nil ? "Running" : "Not running")
        })
        .navigationSubtitle(!loader.hasChanges ? "" : "Edited")
        .padding()
        .frame(minHeight: 200)
        .alert(loader.error?.error.localizedDescription ?? "Error", isPresented: $loader.hasError, actions: {}, message: {
            if let error = loader.error?.error {
                ErrorView(error: error)
            }
        })
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
}
