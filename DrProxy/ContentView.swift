//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import FileService

struct ContentView: View {
    enum Modal: Identifiable {
        case changePassword

        var id: Self { self }
    }

    @AppStorage(AppStorage.configPathKey) private var configPath: String = AppStorage.configPathDefault
    @AppStorage(AppStorage.jobNameKey) private var jobName: String = AppStorage.jobNameDefault

    @State private var savedFile: ConfigFile?
    @State private var file = ConfigFile()
    @State private var password = "password"

    @State private var modal: Modal?

    private var hasChanges: Bool {
        savedFile != file
    }

    var body: some View {
        Form {
            Section(header: Text("Credentials")) {
                TextField("Username", text: $file.username).disabled(true)
                TextField("Domain", text: $file.domain).disabled(true)
                HStack {
                    SecureField("Password", text: $password).disabled(true)
                    Button("Change…", action: changePassword)
                }
            }
            Section(header: Text("Proxy")) {
                TextField("Upstream", text: $file.proxy)
                TextField("Bypass", text: $file.noProxy)
                TextField("Port", text: $file.listen)
                TextField("Gateway", text: $file.gateway)
            }
            Section {
                HStack {
                    Spacer()
                    Button("Save", action: save)
                        .buttonStyle(DefaultButtonStyle())
                        .environment(\.isEnabled, hasChanges)
                }
            }
        }
        .toolbar(content: {
            Image(systemName: "info.circle")
        })
        .navigationSubtitle(savedFile == file ? "" : "Edited")
        .padding()
        .frame(minHeight: 200)
        .sheet(item: $modal, content: { modal in
            switch modal {
            case .changePassword:
                ChangePasswordView(configFile: $file)
            }
        })
        .task {
            do {
                try await load()
            } catch {
                print("error \(error)")
            }
        }
    }

    private func load() async throws {
        let content = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            let url = URL(fileURLWithPath: configPath)
            NSXPCConnection.fileService.readFile(url: url) { error, content in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let content = content {
                    cont.resume(returning: content)
                } else {
                    fatalError()
                }
            }
        }
        file = try ConfigFile(string: content)
        savedFile = file
    }

    private func save() {
        Task {
            do {
                try await save()
                savedFile = file
            } catch {
                print("error \(error)")
            }
        }
    }

    private func save() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let url = URL(fileURLWithPath: configPath)
            NSXPCConnection.fileService.writeFile(url: url, content: file.string) { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }

    private func changePassword() {
        modal = .changePassword
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
