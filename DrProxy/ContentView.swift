//
//  ContentView.swift
//  DrProxy
//
//  Created by Gareth Redman on 26/11/21.
//

import SwiftUI

import FileService

struct ContentView: View {
    @Binding var document: ConfigDocument

    var body: some View {
        EditorView(document: $document)
            .toolbar(content: {
                Image(systemName: "info.circle")
            })
            .navigationSubtitle(!document.hasChanges ? "" : "Edited")
            .padding()
            .frame(minHeight: 200)
            .alert(document.error?.error.localizedDescription ?? "Error", isPresented: $document.hasError, actions: {}, message: {
                if let error = document.error?.error {
                    ErrorView(error: error)
                }
            })
    }
}
