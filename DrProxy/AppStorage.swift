//
//  AppStorage.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

extension AppStorage where Value == String {
    static let configBookmarkKey = "configBookmark"
    static let jobNameKey = "jobName"

    static let configPathDefault = "/usr/local/etc"
    static let jobNameDefault = "homebrew.mxcl.cntlm"
}
