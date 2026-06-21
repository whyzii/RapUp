//
//  writeV1App.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 09/12/25.
//

import SwiftUI

@main
struct writeV1App: App {
    @StateObject private var library = LibraryViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
        }
    }
}


