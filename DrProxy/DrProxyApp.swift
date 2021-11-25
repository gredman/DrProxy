//
//  DrProxyApp.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

@main
struct DrProxyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            PreferencesView()
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
        }.padding()
    }
}
