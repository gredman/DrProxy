//
//  DrProxyApp.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

@main
struct DrProxyApp: App, Sendable {
    @StateObject var loader = ConfigLoader()
    @StateObject var jobState: JobState

    @AppStorage(AppStorage.jobLabelKey) var jobLabel = AppStorage.jobLabelDefault

    init() {
        _jobState = StateObject(wrappedValue: JobState(label: AppStorage.jobLabelDefault))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(loader: loader, jobState: jobState, openFileAction: open, saveFileAction: save)
                .task {
                    await load()
                    await jobState.setLabel(jobLabel)
                    await jobState.loop()
                }
                .onAppear {
                    Task {
                        NSWindow.allowsAutomaticWindowTabbing = false
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open", action: open)
                    .keyboardShortcut("o")
            }
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
}

private struct PreferencesView: View, Sendable {
    @ObservedObject var jobState: JobState

    @AppStorage(AppStorage.jobLabelKey) var jobLabel: String = AppStorage.jobLabelDefault

    var body: some View {
        Form {
            TextField("Job Label", text: $jobLabel, prompt: Text(AppStorage.jobLabelDefault))
        }
        .onChange(of: jobLabel, perform: updateJobState)
        .padding()
        .frame(width: 400)
    }

    private func updateJobState(_ jobLabel: String) {
        Task {
            await jobState.setLabel(jobLabel)
        }
    }
}
