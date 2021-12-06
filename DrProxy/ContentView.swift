//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var document: ConfigDocument

    var body: some View {
        VStack {
            EditorView(document: document)
                .environment(\.isEnabled, document.isLoaded)
            HStack {
                Spacer()
                Button("Open", action: open)
                Button("Save", action: save)
                    .buttonStyle(DefaultButtonStyle())
                    .environment(\.isEnabled, document.hasChanges)
            }
        }
        .toolbar(content: {
            Image(systemName: "info.circle")
        })
        .navigationSubtitle(!document.hasChanges ? "" : "Edited")
        .padding()
        .frame(minHeight: 200)
        .alert(document.error?.error.localizedDescription ?? "Error", isPresented: $document.hasError, actions: {}, message: {
            if let error = document.error?.error {
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
            await document.load(path: url.path)
        }
    }

    private func save() {
        Task {
            await document.save()
        }
    }
}
