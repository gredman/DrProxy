//
//  AppStorage.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

extension AppStorage where Value == String {
    static let configPathKey = "configPath"
    static let jobNameKey = "jobName"

    static let configPathDefault = "/usr/local/etc/cntlm.conf"
    static let jobNameDefault = "homebrew.mxcl.cntlm"
}
