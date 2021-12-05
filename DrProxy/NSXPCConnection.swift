//
//  NSXPCConnection.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import Foundation

import Services

extension NSXPCConnection {
    static var hashService: HashServiceProtocol = {
        let connection = NSXPCConnection(serviceName: "computer.gareth.DrProxy.HashService")
        connection.remoteObjectInterface = NSXPCInterface(with: HashServiceProtocol.self)
        connection.resume()

        return connection.remoteObjectProxyWithErrorHandler({ error in
            fatalError("remote proxy error: \(error)")
        }) as! HashServiceProtocol
    }()

    static var launchService: LaunchServiceProtocol = {
        let connection = NSXPCConnection(serviceName: "computer.gareth.DrProxy.LaunchService")
        connection.remoteObjectInterface = NSXPCInterface(with: LaunchServiceProtocol.self)
        connection.resume()

        return connection.remoteObjectProxyWithErrorHandler({ error in
            fatalError("remote proxy error: \(error)")
        }) as! LaunchServiceProtocol
    }()
}
