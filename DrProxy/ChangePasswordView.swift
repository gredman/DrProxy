//
//  ChangePasswordView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import HashService

struct ChangePasswordView: View {
    var configFile: Binding<ConfigFile>

    @Environment(\.presentationMode) var presentationMode

    @State private var domain = ""
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Domain", text: $domain, prompt: Text("network"))
            TextField("Username", text: $username, prompt: Text("dale_cooper"))
            SecureField("Password", text: $password, prompt: Text("password01"))
            HStack {
                Button("Cancel", action: cancel)
                Button("Update", action: updatePassword)
                    .environment(\.isEnabled, isValid)
            }
        }
        .onAppear(perform: {
            self.domain = configFile.domain.wrappedValue
            self.username = configFile.username.wrappedValue
        })
        .padding()
    }

    private var isValid: Bool {
        !domain.isEmpty && !username.isEmpty && !password.isEmpty
    }

    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }

    private func updatePassword() {
        Task {
            await updatePassword()
        }
    }

    private func updatePassword() async {
        guard let hash = await withCheckedContinuation({ cont in
            NSXPCConnection.hashService.computeHash(domain: domain, username: username, password: password, withReply: cont.resume(returning:))
        }) else {
            return
        }

        configFile.domain.wrappedValue = domain
        configFile.username.wrappedValue = username

        configFile.passLM.wrappedValue = hash.passLM ?? ""
        configFile.passNT.wrappedValue = hash.passNT ?? ""
        configFile.passNTLMv2.wrappedValue = hash.passNTLMv2 ?? ""

        presentationMode.wrappedValue.dismiss()
    }
}

private extension PasswordHash {
    var passLM: String? {
        self["PassLM"] as? String
    }
    var passNT: String? {
        self["PassNT"] as? String
    }
    var passNTLMv2: String? {
        self["PassNTLMv2"] as? String
    }
}

