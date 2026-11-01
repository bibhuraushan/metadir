//
//  MetaDirApp.swift
//  MetaDir
//

import SwiftUI

@main
struct MetaDirApp: App {
    @StateObject private var viewModel = MetadataViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onOpenURL(perform: viewModel.open(requestURL:))
        }
        .defaultSize(width: 540, height: 720)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
