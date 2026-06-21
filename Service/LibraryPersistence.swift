//
//  LibraryPersistence.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 15/12/25.
//

import Foundation


final class LibraryPersistence {
    private let fileName = "library.json"

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func load() -> LibraryData {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(LibraryData.self, from: data)
        } catch {
            return LibraryData()
        }
    }

    func save(_ library: LibraryData) {
        do {
            let data = try JSONEncoder().encode(library)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // optional: print("Save failed:", error)
        }
    }
}
