import SwiftUI
import UIKit

// MARK: - Sidebar selection (regular-width / iPad layout)
enum LibrarySelection: Hashable {
    case lyric(UUID)
    case folder(UUID)
    case bookmarks
    case trash
}

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var path = NavigationPath()

    // iPad / regular-width split view selection
    @State private var selection: LibrarySelection?

    // New folder
    @State private var showNewFolder = false
    @State private var newFolderName = ""

    // Rename lyric
    @State private var renameTarget: LyricDocument?
    @State private var renameText = ""

    // Rename folder
    @State private var renameFolderTarget: LyricFolder?
    @State private var renameFolderText: String = ""

    // Delete folder confirm
    @State private var deleteFolderTarget: LyricFolder?
    @State private var showDeleteFolderConfirm = false

    // Share
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    private var isTrulyEmpty: Bool {
        library.activeDocuments.isEmpty &&
        library.folders.isEmpty &&
        library.bookmarkedDocuments.isEmpty &&
        library.trashedDocuments.isEmpty
    }

    var body: some View {
        Group {
            // Regular width (iPad, larger multitasking panes) gets a proper
            // sidebar + detail layout instead of a stretched-out phone list.
            // Compact width (iPhone) keeps the existing stack behavior
            // completely unchanged.
            if horizontalSizeClass == .compact {
                compactBody
            } else {
                regularBody
            }
        }
        // IMPORTANT: alerts applied as a modifier (no recursion)
        .modifier(LibraryAlertsModifier(
            library: library,
            showNewFolder: $showNewFolder,
            newFolderName: $newFolderName,
            renameTarget: $renameTarget,
            renameText: $renameText,
            renameFolderTarget: $renameFolderTarget,
            renameFolderText: $renameFolderText,
            deleteFolderTarget: $deleteFolderTarget,
            showDeleteFolderConfirm: $showDeleteFolderConfirm
        ))
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
        }
    }

    // MARK: - Compact (iPhone) layout — unchanged from original

    private var compactBody: some View {
        NavigationStack(path: $path) {
            Group {
                if isTrulyEmpty {
                    emptyStateView
                } else {
                    mainListView
                }
            }
            .navigationTitle("Library")
            .searchable(text: $library.searchText, prompt: "Search lyrics")
            .navigationDestination(for: UUID.self) { id in
                let binding = library.bindingForDocumentOptional(id)
                OptionalEditorHost(document: binding)
                    .environmentObject(library)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let doc = library.createLyric()
                        path.append(doc.id)
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Lyric")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showNewFolder = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }

                        Divider()

                        Picker("Sort", selection: $library.sort) {
                            ForEach(LibraryViewModel.SortOption.allCases, id: \.self) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More")
                }
            }
        }
    }

    // MARK: - Regular width (iPad) layout

    private var regularBody: some View {
        NavigationSplitView {
            Group {
                if isTrulyEmpty {
                    emptyStateView
                } else {
                    sidebarListView
                }
            }
            .navigationTitle("Library")
            .searchable(text: $library.searchText, prompt: "Search lyrics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let doc = library.createLyric()
                        selection = .lyric(doc.id)
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Lyric")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showNewFolder = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }

                        Divider()

                        Picker("Sort", selection: $library.sort) {
                            ForEach(LibraryViewModel.SortOption.allCases, id: \.self) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More")
                }
            }
        } detail: {
            NavigationStack {
                detailContent
            }
        }
    }

    private var sidebarListView: some View {
        List(selection: $selection) {
            if !library.folders.isEmpty {
                Section("Folders") {
                    ForEach(library.folders) { folder in
                        Label(folder.name, systemImage: "folder")
                            .tag(LibrarySelection.folder(folder.id))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    renameFolderTarget = folder
                                    renameFolderText = folder.name
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFolderTarget = folder
                                    showDeleteFolderConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            Section("All Lyrics") {
                ForEach(library.activeDocuments) { doc in
                    lyricRow(doc)
                        .tag(LibrarySelection.lyric(doc.id))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                library.toggleBookmark(doc.id)
                            } label: {
                                Label(doc.isBookmarked ? "Unbookmark" : "Bookmark",
                                      systemImage: doc.isBookmarked ? "bookmark.fill" : "bookmark")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                library.moveToTrash(doc.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                renameTarget = doc
                                renameText = doc.title
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)

                            Button {
                                presentShare(for: doc)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.gray)
                        }
                        .contextMenu {
                            Button { presentShare(for: doc) } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }

                            Button { library.toggleBookmark(doc.id) } label: {
                                Label(doc.isBookmarked ? "Remove Bookmark" : "Bookmark",
                                      systemImage: doc.isBookmarked ? "bookmark.slash" : "bookmark")
                            }

                            Button { library.duplicateLyric(doc.id) } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button {
                                renameTarget = doc
                                renameText = doc.title
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                library.moveToTrash(doc.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                if library.activeDocuments.isEmpty {
                    Text("No lyrics in Library.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if !library.bookmarkedDocuments.isEmpty {
                    Label("Bookmarks", systemImage: "bookmark")
                        .tag(LibrarySelection.bookmarks)
                }

                Label("Trash", systemImage: "trash")
                    .tag(LibrarySelection.trash)
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selection {
        case .lyric(let id):
            OptionalEditorHost(document: library.bindingForDocumentOptional(id))
                .environmentObject(library)
        case .folder(let id):
            if let folder = library.folders.first(where: { $0.id == id }) {
                FolderDetailView(folder: folder)
                    .environmentObject(library)
            } else {
                emptySelectionPlaceholder
            }
        case .bookmarks:
            BookmarksView()
                .environmentObject(library)
        case .trash:
            TrashView()
                .environmentObject(library)
        case .none:
            emptySelectionPlaceholder
        }
    }

    private var emptySelectionPlaceholder: some View {
        ContentUnavailableView {
            Label("No Lyric Selected", systemImage: "music.note.list")
        } description: {
            Text("Choose a lyric from the list, or create a new one.")
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No lyrics yet", systemImage: "doc.text")
        } description: {
            Text("Create a lyric or organize your writing into folders.")
        } actions: {
            Button("New Lyric") {
                let doc = library.createLyric()
                if horizontalSizeClass == .compact {
                    path.append(doc.id)
                } else {
                    selection = .lyric(doc.id)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding()
    }

    private var mainListView: some View {
        List {
            foldersSection
            allLyricsSection
            utilitySection
        }
    }

    private var foldersSection: some View {
        Group {
            if !library.folders.isEmpty {
                Section("Folders") {
                    ForEach(library.folders) { folder in
                        NavigationLink(folder.name) {
                            FolderDetailView(folder: folder)
                                .environmentObject(library)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                renameFolderTarget = folder
                                renameFolderText = folder.name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteFolderTarget = folder
                                showDeleteFolderConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var allLyricsSection: some View {
        Section("All Lyrics") {
            ForEach(library.activeDocuments) { doc in
                NavigationLink(value: doc.id) {
                    lyricRow(doc)
                }
                // Swipe RIGHT = Bookmark
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        library.toggleBookmark(doc.id)
                    } label: {
                        Label(doc.isBookmarked ? "Unbookmark" : "Bookmark",
                              systemImage: doc.isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .tint(.blue)
                }
                // Swipe LEFT = Delete / Rename / Share
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        library.moveToTrash(doc.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        renameTarget = doc
                        renameText = doc.title
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.orange)

                    Button {
                        presentShare(for: doc)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.gray)
                }
                // Long press menu (Notes-like; no preview to keep it stable)
                .contextMenu {
                    Button { presentShare(for: doc) } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button { library.toggleBookmark(doc.id) } label: {
                        Label(doc.isBookmarked ? "Remove Bookmark" : "Bookmark",
                              systemImage: doc.isBookmarked ? "bookmark.slash" : "bookmark")
                    }

                    Button { library.duplicateLyric(doc.id) } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button {
                        renameTarget = doc
                        renameText = doc.title
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        library.moveToTrash(doc.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if library.activeDocuments.isEmpty {
                Text("No lyrics in Library.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var utilitySection: some View {
        Section {
            if !library.bookmarkedDocuments.isEmpty {
                NavigationLink {
                    BookmarksView()
                        .environmentObject(library)
                } label: {
                    Label("Bookmarks", systemImage: "bookmark")
                }
            }

            NavigationLink {
                TrashView()
                    .environmentObject(library)
            } label: {
                Label("Trash", systemImage: "trash")
            }
        }
    }

    private func lyricRow(_ doc: LyricDocument) -> some View {
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

            Image(systemName: doc.isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundStyle(doc.isBookmarked ? Color.blue : Color.secondary)
        }
        .padding(.vertical, 4)
    }

    private func presentShare(for doc: LyricDocument) {
        // Keep stable: share title. Replace later with full lyric text if you want.
        shareItems = [doc.title]
        showShareSheet = true
    }
}

// MARK: - ViewModifier (prevents recursion crash)
private struct LibraryAlertsModifier: ViewModifier {
    let library: LibraryViewModel

    @Binding var showNewFolder: Bool
    @Binding var newFolderName: String

    @Binding var renameTarget: LyricDocument?
    @Binding var renameText: String

    @Binding var renameFolderTarget: LyricFolder?
    @Binding var renameFolderText: String

    @Binding var deleteFolderTarget: LyricFolder?
    @Binding var showDeleteFolderConfirm: Bool

    func body(content: Content) -> some View {
        content
            .alert("New Folder", isPresented: $showNewFolder) {
                TextField("Folder name", text: $newFolderName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                Button("Create") {
                    library.createFolder(name: newFolderName)
                    newFolderName = ""
                }
                .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
            }

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
                Button("Cancel", role: .cancel) {
                    renameTarget = nil
                }
            }

            .alert("Rename Folder", isPresented: Binding(
                get: { renameFolderTarget != nil },
                set: { if !$0 { renameFolderTarget = nil } }
            )) {
                TextField("Folder name", text: $renameFolderText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                Button("Save") {
                    if let folder = renameFolderTarget {
                        library.renameFolder(folder.id, newName: renameFolderText)
                    }
                    renameFolderTarget = nil
                }
                .disabled(renameFolderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {
                    renameFolderTarget = nil
                }
            }

            .alert("Delete Folder?", isPresented: $showDeleteFolderConfirm) {
                Button("Delete", role: .destructive) {
                    if let folder = deleteFolderTarget {
                        library.deleteFolder(folder.id)
                    }
                    deleteFolderTarget = nil
                }
                Button("Cancel", role: .cancel) {
                    deleteFolderTarget = nil
                }
            } message: {
                Text("Lyrics inside will be moved to Library (not deleted).")
            }
    }
}

// MARK: - Optional editor host
struct OptionalEditorHost: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var document: LyricDocument?

    var body: some View {
        Group {
            if let doc = document {
                LyricEditorView(document: Binding(
                    get: { doc },
                    set: { document = $0 }
                ))
                .onChange(of: document) { newValue in
                    if newValue == nil { dismiss() }
                }
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
    }
}

// MARK: - Share Sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
