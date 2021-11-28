//
//  DrProxyApp.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

@main
struct DrProxyApp: App {
    @State var document = ConfigDocument()
    @AppStorage(AppStorage.configPathKey) var configPath: String = AppStorage.configPathDefault

    var body: some Scene {
        WindowGroup {
            ContentView(document: $document)
                .task {
                    await load()
                }
        }
        .commands {
            CommandGroup(replacing: .saveItem) {
                Button("Save", action: save)
                    .keyboardShortcut("s")
            }
        }

        Settings {
            PreferencesView()
        }
    }

    private func load() async {
        do {
            try await document.load(path: configPath)
        } catch {
            print("error \(error)")
        }
    }

    private func save() {
        Task {
            await save()
        }
    }

    private func save() async {
        do {
            try await document.save()
        } catch {
            print("error: \(error)")
        }
    }
}

private struct PreferencesView: View {
    @AppStorage(AppStorage.configPathKey) var configPath: String = AppStorage.configPathDefault
    @AppStorage(AppStorage.jobNameKey) var jobName: String = AppStorage.jobNameDefault

    var body: some View {
        Form {
            TextField("Path", text: $configPath, prompt: Text(AppStorage.configPathDefault))
            TextField("Job Name", text: $jobName, prompt: Text(AppStorage.jobNameDefault))
        }
        .padding()
    }
}
