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
        document.load()
    }

    private func save() {
        document.save()
    }
}

private struct PreferencesView: View {
    @AppStorage(AppStorage.jobNameKey) var jobName: String = AppStorage.jobNameDefault

    var body: some View {
        Form {
            TextField("Job Name", text: $jobName, prompt: Text(AppStorage.jobNameDefault))
        }
        .padding()
    }
}
