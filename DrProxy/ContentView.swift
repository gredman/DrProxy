//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import FileService

struct ContentView: View {
    @AppStorage(AppStorage.configPathKey) var configPath: String = AppStorage.configPathDefault
    @AppStorage(AppStorage.jobNameKey) var jobName: String = AppStorage.jobNameDefault

    @State var fileContent: String = ""

    var body: some View {
        VStack {
            Text(fileContent)
        }
        .padding()
        .task {
            let connection = NSXPCConnection(serviceName: "computer.gareth.DrProxy.FileService")
            connection.remoteObjectInterface = NSXPCInterface(with: FileServiceProtocol.self)
            connection.resume()

            let service = connection.remoteObjectProxyWithErrorHandler({ error in
                print("remote proxy error: \(error)")
            }) as! FileServiceProtocol
            service.readFile(path: configPath) { content in
                fileContent = content ?? ":-("
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
