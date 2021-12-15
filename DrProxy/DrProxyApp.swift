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
            PreferencesView(jobState: jobState)
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
    @ObservedObject var jobState: JobState

    @AppStorage(AppStorage.jobNameKey) var jobLabel: String = AppStorage.jobNameDefault

    var body: some View {
        Form {
            TextField("Job Label", text: $jobLabel, prompt: Text(AppStorage.jobNameDefault))
        }
        .onChange(of: jobLabel, perform: updateJobState)
        .padding()
        .frame(idealWidth: 200)
    }

    private func updateJobState(_ jobLabel: String) {
        Task {
            await jobState.setLabel(jobLabel)
        }
    }
}
