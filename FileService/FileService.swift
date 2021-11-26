//
//  FileService.swift
//  FileService
//
//  Created by Gareth Redman on 18/10/21.
//

import Foundation
import ServiceManagement

@objc public protocol FileServiceProtocol {
    func readFile(path: String, withReply reply: @escaping (String?) -> Void)
}

class FileService: NSObject, FileServiceProtocol {
    func readFile(path: String, withReply reply: @escaping (String?) -> Void) {
        let url = URL(fileURLWithPath: path)
        let string = try? String(contentsOf: url)
        reply(string)
    }
}