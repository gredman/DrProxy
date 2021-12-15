//
//  AppStorage.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

extension AppStorage where Value == String {
    static let configBookmarkKey = "configBookmark"
    static let jobLabelKey = "jobLabel"

    static let configPathDefault = "/usr/local/etc"
    static let jobLabelDefault = "homebrew.mxcl.cntlm"
}
