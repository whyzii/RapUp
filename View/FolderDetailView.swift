import SwiftUI

struct FolderDetailView: View {
    @EnvironmentObject private var library: LibraryViewModel
    let folder: LyricFolder

    @State private var renameTarget: LyricDocument?
    @State private var renameText = ""

    @State private var showAddExisting = false
    @State private var openDoc: DocID?

    // Wrapper so we can programmatically navigate
    struct DocID: Identifiable, Hashable {
        let id: UUID
    }

    var body: some View {
        List {
            let docs = library.documents(inFolder: folder.id)

            if docs.isEmpty {
                ContentUnavailableView {
                    Label("No lyrics in this folder", systemImage: "folder")
                } description: {
                    Text("Create a new lyric here, or add an existing lyric from your Library.")
                } actions: {
                    Button("New Lyric") {
                        let doc = library.createLyric(inFolder: folder.id)
                        openDoc = DocID(id: doc.id) // auto-open
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)

                    Button("Add Existing") {
                        showAddExisting = true
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                .padding(.vertical, 16)
            } else {
                Section(folder.name) {
                    ForEach(docs) { doc in
                        NavigationLink {
                            OptionalEditorHost(document: library.bindingForDocumentOptional(doc.id))
                                .environmentObject(library)
                        } label: {
                            folderLyricRow(doc)
                        }
                        .contextMenu {
                            Menu {
                                Button {
                                    renameTarget = doc
                                    renameText = doc.title
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }

                                Button {
                                    library.duplicateLyric(doc.id)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }

                                Button {
                                    library.moveLyric(doc.id, toFolder: nil)
                                } label: {
                                    Label("Remove from Folder", systemImage: "folder.badge.minus")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    library.moveToTrash(doc.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                Label("More", systemImage: "ellipsis")
                            }
                        }
                        // Keep swipes for admin actions only (rename/duplicate/remove/delete)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                renameTarget = doc
                                renameText = doc.title
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)

                            Button {
                                library.duplicateLyric(doc.id)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)

                            Button {
                                library.moveLyric(doc.id, toFolder: nil)
                            } label: {
                                Label("Remove", systemImage: "folder.badge.minus")
                            }
                            .tint(.gray)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                library.moveToTrash(doc.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)

        // Folder actions
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        let doc = library.createLyric(inFolder: folder.id)
                        openDoc = DocID(id: doc.id) // auto-open
                    } label: {
                        Label("New Lyric", systemImage: "square.and.pencil")
                    }

                    Button {
                        showAddExisting = true
                    } label: {
                        Label("Add Existing", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add")
            }
        }

        // Programmatic open after create (no extra NavigationStack)
        .navigationDestination(item: $openDoc) { item in
            OptionalEditorHost(document: library.bindingForDocumentOptional(item.id))
                .environmentObject(library)
        }

        // Add existing sheet
        .sheet(isPresented: $showAddExisting) {
            AddExistingToFolderSheet(folder: folder)
                .environmentObject(library)
        }

        // Rename
        .alert("Rename Lyric", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Title", text: $renameText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
            Button("Save") {
                if let target = renameTarget {
                    library.renameLyric(target.id, newTitle: renameText)
                }
                renameTarget = nil
            }
            .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
    }

    private func folderLyricRow(_ doc: LyricDocument) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(doc.title).font(.headline).lineLimit(1)
                Text(doc.updatedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                library.toggleBookmark(doc.id)
            } label: {
                Image(systemName: doc.isBookmarked ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(doc.isBookmarked ? "Remove bookmark" : "Add bookmark")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sheet: Add existing lyrics to folder
struct AddExistingToFolderSheet: View {
    @EnvironmentObject private var library: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    let folder: LyricFolder

    var body: some View {
        NavigationStack {
            List {
                let candidates = library.availableDocumentsToAdd(toFolder: folder.id)

                if candidates.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing to add", systemImage: "doc")
                    } description: {
                        Text("All your lyrics are already in this folder, or you have no lyrics yet.")
                    }
                    .padding(.vertical, 24)
                } else {
                    ForEach(candidates) { doc in
                        Button {
                            library.moveLyric(doc.id, toFolder: folder.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(doc.title).font(.headline).lineLimit(1)
                                Text(doc.updatedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Add to \(folder.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
