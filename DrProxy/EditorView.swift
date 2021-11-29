//
//  EditorView.swift
//  DrProxy
//
//  Created by Gareth Redman on 29/11/21.
//

import SwiftUI

private extension Binding where Value == Bool {
    init(_ binding: Binding<String>) {
        self.init {
            binding.wrappedValue == "yes"
        } set: { newValue, _ in
            binding.wrappedValue = newValue ? "yes" : "no"
        }
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
                Toggle("Gateway", isOn: Binding($document.file.gateway))
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
