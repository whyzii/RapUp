import SwiftUI

struct LyricEditorView: View {
    @Binding var document: LyricDocument

    @StateObject var viewModel = LyricViewModel()
    @FocusState private var focusedLineID: UUID?
    @Environment(\.editMode) private var editMode
    @EnvironmentObject private var library: LibraryViewModel

    // Rename popup (alert)
    @State private var showRenameAlert = false
    @State private var renameText: String = ""

    // Pending delete confirmation for non-empty lines
    @State private var pendingDelete: (sectionID: UUID, lineID: UUID)?

    var body: some View {
        rootView
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete this line?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let pending = pendingDelete {
                        if focusedLineID == pending.lineID { focusedLineID = nil }
                        withAnimation {
                            viewModel.deleteLine(lineID: pending.lineID, fromSectionID: pending.sectionID)
                        }
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This action can’t be undone.")
            }
            .alert("Rename Title", isPresented: $showRenameAlert) {
                TextField("Title", text: $renameText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    // Persist via view model to ensure save
                    library.renameLyric(document.id, newTitle: trimmed)
                }
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a new title for your lyric.")
            }
    }

    private var rootView: some View {
        content
            .toolbar { trailingToolbar }
            .safeAreaInset(edge: .bottom, spacing: 0) { rhymeAccessoryBar }
            .background(dismissKeyboardBackground)
            .onAppear {
                viewModel.sections = document.sections
                viewModel.isEditing = false
            }
            .onChange(of: document.id) { _ in
                viewModel.sections = document.sections
            }
            .onChange(of: viewModel.sections) { newSections in
                // Update local binding for UI, then persist via library
                document.sections = newSections
                document.updatedAt = Date()
                library.updateSections(for: document.id, sections: newSections)

                if shouldAutoTitle(document.title),
                   let suggested = suggestedTitle(from: newSections) {
                    library.renameLyric(document.id, newTitle: suggested)
                }
            }
    }

    private var dismissKeyboardBackground: some View {
        Color(UIColor.systemBackground)
            .contentShape(Rectangle())
            .onTapGesture {
                if focusedLineID != nil { focusedLineID = nil }
            }
    }

    // MARK: - Content
    private var content: some View {
        Group {
            if viewModel.sections.isEmpty {
                emptyState
            } else {
                List {
                    mainSectionsLoop
                    addSectionButton
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, editMode)
                .scrollDismissesKeyboard(.interactively)
                .gesture(DragGesture().onChanged { _ in })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 44, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("Start your lyrics")
                .font(.title3).fontWeight(.semibold)

            Text("Add a section to begin writing. You can reorder sections, add lines, and get rhyme suggestions as you type.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                withAnimation { viewModel.addSection(type: .verse) }
            } label: {
                Label("Add Verse", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            focusedLineID = nil
        }
    }

    // MARK: - Sections + Rows
    private var mainSectionsLoop: some View {
        ForEach($viewModel.sections) { $section in
            Section {
                if !section.isCollapsed {
                    ForEach($section.lines) { $line in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            if editMode?.wrappedValue == .active {
                                let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    Button {
                                        pendingDelete = (section.id, line.id)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Delete line")
                                }
                            }

                            LyricLineRow(
                                line: $line,
                                sectionID: section.id,
                                viewModel: viewModel,
                                focusedLineID: $focusedLineID
                            )
                        }
                        .listRowSeparator(.visible)
                        .listRowBackground(Color.clear)
                        .if(editMode?.wrappedValue != .active) { view in
                            view
                                .swipeActions(edge: .leading) {
                                    Button {
                                        viewModel.copyLineText(line.text)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.clipboard")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        let lineID = line.id
                                        let sectionID = section.id
                                        if focusedLineID == lineID { focusedLineID = nil }
                                        DispatchQueue.main.async {
                                            viewModel.deleteLine(lineID: lineID, fromSectionID: sectionID)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.duplicateLine(line: line, in: section.id)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .onMove { indices, newOffset in
                        viewModel.moveLine(from: indices, to: newOffset, in: section)
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.snappy) { section.isCollapsed.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(section.type.color)
                                .frame(width: 6, height: 6)
                            Image(systemName: section.isCollapsed ? "chevron.right" : "chevron.down")
                                .foregroundStyle(.secondary)
                            Text(sectionHeaderTitle(for: section))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if editMode?.wrappedValue != .active {
                        Menu {
                            Button {
                                viewModel.duplicateSectionAtEnd(section)
                            } label: {
                                Label("Duplicate to End", systemImage: "arrow.turn.right.down")
                            }

                            Button {
                                viewModel.duplicateSection(section)
                            } label: {
                                Label("Duplicate Here", systemImage: "doc.on.doc")
                            }

                            Button(role: .destructive) {
                                withAnimation { viewModel.deleteSection(section) }
                            } label: {
                                Label("Delete Section", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .onMove { indices, newOffset in
            viewModel.moveSection(from: indices, to: newOffset)
        }
    }

    private func sectionHeaderTitle(for section: LyricSection) -> String {
        let count = section.lines.count
        let bars = count == 1 ? "bar" : "bars"
        return "\(section.type.rawValue) • \(count) \(bars)"
    }

    private var addSectionButton: some View {
        Section {
            Menu {
                ForEach(SectionType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        viewModel.addSection(type: type)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    Text("Add Section")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedLineID = nil
        }
    }

    // MARK: - Toolbars
    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        if viewModel.isEditing {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.isEditing = false
                    editMode?.wrappedValue = .inactive
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Done")
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let shareText = shareContent() {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        } else if focusedLineID != nil {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    focusedLineID = nil
                    HapticManager.shared.success()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Done")
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { viewModel.performUndo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .disabled(viewModel.undoStack.isEmpty)

                Button { viewModel.performRedo() } label: { Image(systemName: "arrow.uturn.forward") }
                    .disabled(viewModel.redoStack.isEmpty)

                if let shareText = shareContent() {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                editMenu
            }
        } else {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let shareText = shareContent() {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                editMenu
            }
        }
    }

    private var editMenu: some View {
        Menu {
            Button {
                renameText = document.title
                showRenameAlert = true
            } label: {
                Label("Rename Title", systemImage: "pencil")
            }

            Divider()

            Button {
                focusedLineID = nil
                viewModel.isEditing = true
                editMode?.wrappedValue = .active
            } label: {
                Label("Edit Lyric", systemImage: "slider.horizontal.3")
            }
        } label: {
            Text("Edit")
        }
        .accessibilityLabel("Edit")
    }

    // MARK: - Rhyme Accessory
    @ViewBuilder
    private var rhymeAccessoryBar: some View {
        if !viewModel.suggestedRhymes.isEmpty && focusedLineID != nil && !viewModel.isEditing {
            VStack(spacing: 0) {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text(rhymeTrayLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)

                        ForEach(viewModel.suggestedRhymes, id: \.self) { rhyme in
                            Button {
                                insertRhyme(rhyme)
                            } label: {
                                Text(rhyme)
                                    .font(.callout)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.thinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .background(.bar)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func insertRhyme(_ rhyme: String) {
        guard let sectionIndex = viewModel.sections.firstIndex(where: { section in
            section.lines.contains(where: { $0.id == focusedLineID })
        }) else { return }
        guard let lineIndex = viewModel.sections[sectionIndex].lines.firstIndex(where: { $0.id == focusedLineID }) else { return }

        var line = viewModel.sections[sectionIndex].lines[lineIndex]
        let separator = line.text.isEmpty ? "" : " "
        line.text += "\(separator)\(rhyme)"
        viewModel.sections[sectionIndex].lines[lineIndex] = line
    }

    private var rhymeTrayLabel: String {
        viewModel.rhymeTargetWord.isEmpty ? "Rhymes" : "Rhymes for \u{201C}\(viewModel.rhymeTargetWord)\u{201D}"
    }

    private func shareContent() -> String? {
        guard !viewModel.sections.isEmpty else { return nil }
        let body = viewModel.sections.map { section in
            let header = "[\(section.type.rawValue)]"
            let lines = section.lines.map(\.text).joined(separator: "\n")
            return "\(header)\n\(lines)"
        }.joined(separator: "\n\n")
        return "\(document.title)\n\n\(body)"
    }

    // MARK: - Auto Title Helpers

    private func shouldAutoTitle(_ currentTitle: String) -> Bool {
        let t = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty || t == "Untitled Lyric"
    }

    private func suggestedTitle(from sections: [LyricSection]) -> String? {
        let firstNonEmptyLine = sections
            .flatMap(\.lines)
            .map(\.text)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let line = firstNonEmptyLine else { return nil }

        let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = cleaned.split(whereSeparator: { $0.isWhitespace })
        guard !words.isEmpty else { return nil }

        let maxWords = 6
        var title = words.prefix(maxWords).joined(separator: " ")

        let maxChars = 32
        if title.count > maxChars {
            title = String(title.prefix(maxChars)).trimmingCharacters(in: .whitespacesAndNewlines)
            title += "…"
            return title
        }

        if words.count > maxWords {
            title += "…"
        }

        return title
    }
}

// Small helper to conditionally apply modifiers in a chain.
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
