//
//  NSXPCConnection.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import Foundation

import FileService
import HashService

extension NSXPCConnection {
    static var fileService: FileServiceProtocol = {
        let connection = NSXPCConnection(serviceName: "computer.gareth.DrProxy.FileService")
        connection.remoteObjectInterface = NSXPCInterface(with: FileServiceProtocol.self)
        connection.resume()

        return connection.remoteObjectProxyWithErrorHandler({ error in
            fatalError("remote proxy error: \(error)")
        }) as! FileServiceProtocol
    }()

    static var hashService: HashServiceProtocol = {
        let connection = NSXPCConnection(serviceName: "computer.gareth.DrProxy.HashService")
        connection.remoteObjectInterface = NSXPCInterface(with: HashServiceProtocol.self)
        connection.resume()

        return connection.remoteObjectProxyWithErrorHandler({ error in
            fatalError("remote proxy error: \(error)")
        }) as! HashServiceProtocol
    }()
}
