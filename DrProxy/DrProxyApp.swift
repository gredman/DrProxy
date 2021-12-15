//
//  DrProxyApp.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

@main
struct DrProxyApp: App {
    @StateObject var loader = ConfigLoader()
    @StateObject var jobState = JobState(label: AppStorage.jobNameDefault)

    @AppStorage(AppStorage.jobNameKey) var jobName = AppStorage.jobNameDefault

    var body: some Scene {
        WindowGroup {
            ContentView(loader: loader, jobState: jobState)
                .task {
                    await load()
                    await jobState.setLabel(jobName)
                    await jobState.loop()
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
        await loader.load()
    }

    private func save() {
        Task {
            await loader.save()
        }
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
