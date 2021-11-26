//
//  FileService.swift
//  FileService
//
//  Created by Gareth Redman on 18/10/21.
//

import Foundation
import ServiceManagement

@objc public protocol FileServiceProtocol {
    func readFile(path: String, withReply reply: @escaping (NSError?, String?) -> Void)
}

class FileService: NSObject, FileServiceProtocol {
    func readFile(path: String, withReply reply: @escaping (NSError?, String?) -> Void) {
        let url = URL(fileURLWithPath: path)
        let string: String
        do {
            string = try String(contentsOf: url)
        } catch {
            reply(error as NSError, nil)
            return
        }
        reply(nil, string)
    }
}
