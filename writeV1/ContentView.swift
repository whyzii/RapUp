//
//  ContentView.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 09/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    ContentView()
        .environmentObject(LibraryViewModel())
}
