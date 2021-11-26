//
//  ChangePasswordView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import HashService

struct ChangePasswordView: View {
    let configFile: Binding<ConfigFile>

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
            }
        }
        .onAppear(perform: {
            self.domain = configFile.domain.wrappedValue
            self.username = configFile.username.wrappedValue
        })
        .padding()
    }

    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }

    private func updatePassword() {
        let connection = NSXPCConnection(serviceName: "computer.gareth.DrProxy.HashService")
        connection.remoteObjectInterface = NSXPCInterface(with: HashServiceProtocol.self)
        connection.resume()

        let service = connection.remoteObjectProxyWithErrorHandler({ error in
            print("remote proxy error: \(error)")
        }) as! HashServiceProtocol

        service.computeHash(domain: domain, username: username, password: password) { hash in
            print("got hash \(hash)")
        }
//        let content = await service.readFile(path: configPath)
//        do {
//            file = try content.map(ConfigFile.init(string:)) ?? file
//        } catch {
//            print("error \(error)")
//        }
    }
}
