//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import FileService

struct ContentView: View {
    @Binding var document: ConfigDocument

    var body: some View {
        EditorView(document: $document)
            .toolbar(content: {
                Image(systemName: "info.circle")
            })
            .navigationSubtitle(!document.hasChanges ? "" : "Edited")
            .padding()
            .frame(minHeight: 200)
//            .sheet(item: $document.error) { wrapper in
//                ErrorView(error: wrapper.error)
//            }

            .alert(document.error?.error.localizedDescription ?? "Error", isPresented: $document.hasError, actions: {}, message: {
                if let error = document.error?.error {
                    ErrorView(error: error)
                }
            })
    }
}

struct EditorView: View {
    enum Modal: Identifiable {
        case changePassword

        var id: Self { self }
    }

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
        .sheet(item: $modal, content: { modal in
            switch modal {
            case .changePassword:
                ChangePasswordView(configFile: $document.file)
            }
        })
    }

    private func save() {
        Task {
            await document.save()
        }
    }

    private func changePassword() {
        modal = .changePassword
    }
}
