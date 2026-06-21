//
//  LibraryModels.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 15/12/25.
//

import Foundation


struct LyricFolder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
}

struct LyricDocument: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var folderID: UUID? = nil
    var isBookmarked: Bool = false


    // Your existing editor content:
    var sections: [LyricSection]

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Trash (soft delete)
    var isDeleted: Bool = false
    var deletedAt: Date? = nil
}

struct LibraryData: Codable, Equatable {
    var folders: [LyricFolder] = []
    var documents: [LyricDocument] = []
}
