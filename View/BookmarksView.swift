//
//  BookmarksView.swift
//  writeV1
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        List {
            if library.bookmarkedDocuments.isEmpty {
                ContentUnavailableView {
                    Label("No bookmarks", systemImage: "bookmark")
                } description: {
                    Text("Bookmark lyrics to find them quickly here.")
                }
                .padding(.vertical, 24)
            } else {
                Section("Bookmarks") {
                    ForEach(library.bookmarkedDocuments) { doc in
                        NavigationLink {
                            OptionalEditorHost(document: library.bindingForDocumentOptional(doc.id))
                                .environmentObject(library)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(doc.title)
                                        .font(.headline)
                                        .lineLimit(1)

                                    Text(doc.updatedAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    library.toggleBookmark(doc.id) // unbookmark
                                } label: {
                                    Image(systemName: "bookmark.fill")
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove bookmark")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BookmarksView()
            .environmentObject(LibraryViewModel())
    }
}
