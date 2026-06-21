//
//  LibraryViewModel.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 15/12/25.
//

import SwiftUI
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var folders: [LyricFolder] = []
    @Published private(set) var documents: [LyricDocument] = []

    @Published var searchText: String = ""
    @Published var sort: SortOption = .updatedDesc

    private let persistence = LibraryPersistence()

    enum SortOption: String, CaseIterable {
        case updatedDesc = "Recently Updated"
        case titleAsc = "Title A–Z"
        case createdDesc = "Recently Created"
    }

    init() {
        let data = persistence.load()
        folders = data.folders
        documents = data.documents
    }

    // MARK: - Bindings (key to avoid editing LyricView)
    func bindingForDocument(_ id: UUID) -> Binding<LyricDocument> {
        Binding(
            get: {
                guard let existing = self.documents.first(where: { $0.id == id }) else {
                    return LyricDocument(title: "Untitled Lyric", sections: [])
                }
                return existing
            },
            set: { updated in
                if let idx = self.documents.firstIndex(where: { $0.id == id }) {
                    self.documents[idx] = updated
                    self.persist()
                }
            }
        )
    }

    // Optional, safer binding that becomes nil when the document disappears.
    func bindingForDocumentOptional(_ id: UUID) -> Binding<LyricDocument?> {
        Binding<LyricDocument?>(
            get: {
                self.documents.first(where: { $0.id == id })
            },
            set: { updated in
                if let updated, let idx = self.documents.firstIndex(where: { $0.id == id }) {
                    self.documents[idx] = updated
                    self.persist()
                } else {
                    // If updated is nil or the document no longer exists, do nothing.
                }
            }
        )
    }

    // MARK: - Derived
    var activeDocuments: [LyricDocument] {
        filterAndSort(documents.filter { !$0.isDeleted })
    }

    func documents(in folderID: UUID) -> [LyricDocument] {
        filterAndSort(documents.filter { !$0.isDeleted && $0.folderID == folderID })
    }

    var trashedDocuments: [LyricDocument] {
        filterAndSort(documents.filter { $0.isDeleted })
    }

    private func filterAndSort(_ docs: [LyricDocument]) -> [LyricDocument] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = trimmed.isEmpty ? docs : docs.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }

        switch sort {
        case .updatedDesc:
            return searched.sorted { $0.updatedAt > $1.updatedAt }
        case .titleAsc:
            return searched.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .createdDesc:
            return searched.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - CRUD
    func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        folders.insert(LyricFolder(name: trimmed), at: 0)
        persist()
    }

    @discardableResult
    func createLyric(in folderID: UUID? = nil) -> LyricDocument {
        let doc = LyricDocument(
            title: "Untitled Lyric",
            folderID: folderID,
            sections: defaultSections()
        )
        documents.insert(doc, at: 0)
        persist()
        return doc
    }

    func renameLyric(_ id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].title = trimmed
        documents[idx].updatedAt = Date()
        persist()
    }

    // New: update sections and persist
    func updateSections(for id: UUID, sections: [LyricSection]) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].sections = sections
        documents[idx].updatedAt = Date()
        persist()
    }

    func duplicateLyric(_ id: UUID) {
        guard let original = documents.first(where: { $0.id == id }) else { return }
        var copy = original
        copy.id = UUID()
        copy.title = "\(original.title) Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.isDeleted = false
        copy.deletedAt = nil
        documents.insert(copy, at: 0)
        persist()
    }

    func moveToTrash(_ id: UUID) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].isDeleted = true
        documents[idx].deletedAt = Date()
        persist()
    }

    func restoreFromTrash(_ id: UUID) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].isDeleted = false
        documents[idx].deletedAt = nil
        documents[idx].updatedAt = Date()
        persist()
    }

    func deletePermanently(_ id: UUID) {
        documents.removeAll { $0.id == id }
        persist()
    }

    func emptyTrash() {
        documents.removeAll { $0.isDeleted }
        persist()
    }

    // MARK: - Helpers
    private func persist() {
        persistence.save(LibraryData(folders: folders, documents: documents))
    }

    private func defaultSections() -> [LyricSection] {
        [
            LyricSection(type: .verse, lines: [LyricLine(text: "")]),
            LyricSection(type: .chorus, lines: [LyricLine(text: "")])
        ]
    }
    
    func renameFolder(_ id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[idx].name = trimmed
        persist()
    }

    /// Deletes the folder and moves its lyrics to root (folderID = nil)
    func deleteFolder(_ id: UUID) {
        // Move docs out of the folder so nothing becomes “orphaned”
        for i in documents.indices {
            if documents[i].folderID == id {
                documents[i].folderID = nil
                documents[i].updatedAt = Date()
            }
        }

        folders.removeAll { $0.id == id }
        persist()
    }
    
    // MARK: - Bookmarks

    func toggleBookmark(_ id: UUID) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].isBookmarked.toggle()
        persist()
    }

    var bookmarkedDocuments: [LyricDocument] {
        activeDocuments.filter { $0.isBookmarked }
    }

    // MARK: - Folder helpers (so folder lists respect search/sort too)

    func documents(inFolder folderID: UUID) -> [LyricDocument] {
        activeDocuments.filter { $0.folderID == folderID }
    }
    
    // MARK: - Folder assignment

    func moveLyric(_ id: UUID, toFolder folderID: UUID?) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].folderID = folderID
        documents[idx].updatedAt = Date()
        persist()
    }

    /// Creates a new lyric and immediately places it in the folder.
    func createLyric(inFolder folderID: UUID) -> LyricDocument {
        let doc = createLyric()
        moveLyric(doc.id, toFolder: folderID)
        return doc
    }

    func availableDocumentsToAdd(toFolder folderID: UUID) -> [LyricDocument] {
        activeDocuments.filter { $0.folderID != folderID }
    }
}
