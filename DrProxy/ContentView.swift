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

    @AppStorage(AppStorage.configPathKey) var configPath: String = AppStorage.configPathDefault
    @AppStorage(AppStorage.jobNameKey) var jobName: String = AppStorage.jobNameDefault

    @State var file = ConfigFile()
    @State var password = "password"

    @State var modal: Modal?

    var body: some View {
        Form {
            Section(header: Text("Credentials")) {
                Group {
                    TextField("Username", text: $file.username)
                    TextField("Domain", text: $file.domain)
                    SecureField("Password", text: $password)
                    TextField("PassLM", text: $file.passLM)
                    TextField("PassNT", text: $file.passNT)
                    TextField("PassNTLMv2", text: $file.passNTLMv2)
                }.disabled(true)
                Button("Change…", action: changePassword)
            }
        }
        .padding()
        .sheet(item: $modal, content: { modal in
            switch modal {
            case .changePassword:
                ChangePasswordView(configFile: $file)
            }
        })
        .task {
            let content = await withCheckedContinuation { cont in
                NSXPCConnection.fileService.readFile(path: configPath, withReply: cont.resume(returning:))
            }

            do {
                file = try content.map(ConfigFile.init(string:)) ?? file
            } catch {
                print("error \(error)")
            }
        }
    }

    func changePassword() {
        modal = .changePassword
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
