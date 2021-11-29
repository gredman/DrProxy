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
        await document.load(path: configPath)
    }

    private func save() {
        Task {
            await document.save()
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
