//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorage.configPathKey) var configPath: String = AppStorage.configPathDefault
    @AppStorage(AppStorage.jobNameKey) var jobName: String = AppStorage.jobNameDefault

    var body: some View {
        VStack {
            Text(configPath)
            Text(jobName)
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
