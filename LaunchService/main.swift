//
//  main.swift
//  LaunchService
//
//  Created by Gareth Redman on 30/11/21.
//

import Foundation

import Services

@objc class ServiceDelegate : NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: LaunchServiceProtocol.self)
        let exportedObject = LaunchService()
        newConnection.exportedObject = exportedObject
        newConnection.resume()

        return true
    }
}

let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
