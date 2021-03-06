//
//  ChangePasswordView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import Services
import HashService

// struct triggers warnings when conforming to Sendable as of Xcode 13.3b2
struct ChangePasswordView: View {
    @Binding var configFile: ConfigFile

    @Environment(\.presentationMode) var presentationMode

    @State private var domain = ""
    @State private var username = ""
    @State private var password = ""

    @State private var hasError = false
    @State private var error: Error?

    var body: some View {
        Form {
            TextField("Domain", text: $domain, prompt: Text("network"))
            TextField("Username", text: $username, prompt: Text("dale_cooper"))
            SecureField("Password", text: $password, prompt: Text("password01"))
            HStack {
                Button("Cancel", role: .cancel, action: cancel)
                Button("Done", action: updatePassword)
                    .environment(\.isEnabled, isValid)
            }
        }
        .padding()
        .frame(minWidth: 300)
        .onSubmit(updatePassword)
        .onAppear(perform: {
            self.domain = configFile.domain
            self.username = configFile.username
        })
        .alert(error?.localizedDescription ?? "Error", isPresented: $hasError, actions: {}, message: {
            if let error = error {
                ErrorView(error: error)
            }
        })
    }

    private var isValid: Bool {
        !domain.isEmpty && !username.isEmpty && !password.isEmpty
    }

    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }

    private func updatePassword() {
        guard isValid else { return     }
        Task {
            do {
                try await updatePassword()
            } catch {
                self.hasError = true
                self.error = error
            }
        }
    }

    private func updatePassword() async throws {
        let hash = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<PasswordHash, Error>) in
            NSXPCConnection.hashService.computeHash(domain: domain, username: username, password: password) { error, hash in
                if let error = error {
                    cont.resume(throwing: error)
                } else if let hash = hash {
                    cont.resume(returning: hash)
                } else {
                    fatalError("no error or hash")
                }
            }
        }

        configFile.domain = domain
        configFile.username = username

        configFile.passLM = hash.passLM ?? ""
        configFile.passNT = hash.passNT ?? ""
        configFile.passNTLMv2 = hash.passNTLMv2 ?? ""

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
