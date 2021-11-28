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

    @Binding var document: ConfigDocument

    @State private var password = "password"

    @State private var modal: Modal?

    var body: some View {
        Form {
            Section(header: Text("Credentials")) {
                TextField("Username", text: $document.file.username).disabled(true)
                TextField("Domain", text: $document.file.domain).disabled(true)
                HStack {
                    SecureField("Password", text: $password).disabled(true)
                    Button("Change…", action: changePassword)
                }
            }
            Section(header: Text("Proxy")) {
                TextField("Upstream", text: $document.file.proxy)
                TextField("Bypass", text: $document.file.noProxy)
                TextField("Port", text: $document.file.listen)
                TextField("Gateway", text: $document.file.gateway)
            }
            Section {
                HStack {
                    Spacer()
                    Button("Save", action: save)
                        .buttonStyle(DefaultButtonStyle())
                        .environment(\.isEnabled, document.hasChanges)
                }
            }
        }
        .toolbar(content: {
            Image(systemName: "info.circle")
        })
        .navigationSubtitle(!document.hasChanges ? "" : "Edited")
        .padding()
        .frame(minHeight: 200)
        .sheet(item: $modal, content: { modal in
            switch modal {
            case .changePassword:
                ChangePasswordView(configFile: $document.file)
            }
        })
        .task {
            await load()
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
            do {
                try await document.save(path: configPath)
            } catch {
                print("error \(error)")
            }
        }
    }

    private func changePassword() {
        modal = .changePassword
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
