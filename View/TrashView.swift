//
//  TrashView.swift
//  writeV1
//

import SwiftUI

struct TrashView: View {
    @EnvironmentObject private var library: LibraryViewModel

    var body: some View {
        List {
            if library.trashedDocuments.isEmpty {
                ContentUnavailableView {
                    Label("Trash is empty", systemImage: "trash")
                } description: {
                    Text("Deleted lyrics will appear here.")
                }
                .padding(.vertical, 24)
            } else {
                Section("Trash") {
                    ForEach(library.trashedDocuments) { doc in
                        NavigationLink {
                            OptionalEditorHost(document: library.bindingForDocumentOptional(doc.id))
                                .environmentObject(library)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(doc.title)
                                    .font(.headline)
                                    .lineLimit(1)

                                Text(doc.updatedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                library.restoreFromTrash(doc.id)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                library.deletePermanently(doc.id)
                            } label: {
                                Label("Delete", systemImage: "trash.slash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Trash")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TrashView()
            .environmentObject(LibraryViewModel())
    }
}
