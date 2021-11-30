//
//  FileService.swift
//  FileService
//
//  Created by Gareth Redman on 18/10/21.
//

import Foundation
import ServiceManagement

import Services

class FileService: NSObject, FileServiceProtocol {
    func readFile(url: URL, withReply reply: @escaping (NSError?, String?) -> Void) {
        let string: String
        do {
            string = try String(contentsOf: url)
        } catch {
            reply(error as NSError, nil)
            return
        }
        reply(nil, string)
    }

    func writeFile(url: URL, content: String, withReply reply: @escaping (NSError?) -> Void) {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            reply(nil)
        } catch {
            reply(error as NSError)
        }
    }
}
