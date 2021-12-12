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

    @ObservedObject var loader: ConfigLoader

    @State private var password = "password"

    @State private var modal: Modal?

    var body: some View {
        Form {
            Section(header: Text("Credentials")) {
                TextField("Username", text: $loader.file.username).disabled(true)
                TextField("Domain", text: $loader.file.domain).disabled(true)
                HStack {
                    SecureField("Password", text: $password).disabled(true)
                    Button("Change…", action: changePassword)
                }
            }
            Section(header: Text("Proxy")) {
                TextField("Upstream", text: $loader.file.proxy)
                TextField("Bypass", text: $loader.file.noProxy)
                TextField("Port", text: $loader.file.listen)
                Toggle("Gateway", isOn: Binding($loader.file.gateway))
            }
        }
        .sheet(item: $modal, content: { modal in
            switch modal {
            case .changePassword:
                ChangePasswordView(configFile: $loader.file)
            }
        })
    }

    private func changePassword() {
        modal = .changePassword
    }
}
