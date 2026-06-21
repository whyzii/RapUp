//
//  LyricView.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 09/12/25.
//

import SwiftUI

struct LyricView: View {
    @StateObject var viewModel = LyricViewModel()
    @FocusState private var focusedLineID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    @State private var showShareSheet = false
    @State private var navTitle: String = "Summer Rain"
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { leadingToolbar }
                .toolbar { trailingToolbar }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    rhymeAccessoryBar
                }
                .background(Color(UIColor.systemBackground))
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
            .buttonBorderShape(.capsule)
            
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Sections + Rows
    private var mainSectionsLoop: some View {
        ForEach($viewModel.sections) { $section in
            Section {
                if !section.isCollapsed {
                    ForEach($section.lines) { $line in
                        LyricLineRow(
                            line: $line,
                            sectionID: section.id,
                            viewModel: viewModel,
                            focusedLineID: $focusedLineID
                        )
                        .listRowSeparator(.visible)
                        .listRowBackground(Color.clear)
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
                    .onDelete { offsets in
                        deleteLines(at: offsets, in: section)
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
                            Image(systemName: section.isCollapsed ? "chevron.right" : "chevron.down")
                                .foregroundStyle(.secondary)
                            Text(sectionHeaderTitle(for: section))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(section.isCollapsed ? "Expand \(section.type.rawValue)" : "Collapse \(section.type.rawValue)")
                    .accessibilityHint("Toggles visibility of lines in this section")
                    
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
                                .accessibilityLabel("Section actions")
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
    
    private func deleteLines(at offsets: IndexSet, in section: LyricSection) {
        guard let sectionIndex = viewModel.sections.firstIndex(where: { $0.id == section.id }) else { return }
        let ids = offsets.compactMap { idx -> UUID? in
            guard viewModel.sections[sectionIndex].lines.indices.contains(idx) else { return nil }
            return viewModel.sections[sectionIndex].lines[idx].id
        }
        if let focused = focusedLineID, ids.contains(focused) {
            focusedLineID = nil
        }
        DispatchQueue.main.async {
            ids.forEach { id in
                viewModel.deleteLine(lineID: id, fromSectionID: section.id)
            }
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
            .accessibilityLabel("Add new section")
        }
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Toolbars
    @ToolbarContentBuilder
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.backward")
            }
            .accessibilityLabel("Back")
        }
    }
    
    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        if focusedLineID != nil {
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
                .accessibilityHint("Dismisses keyboard")
            }
        } else {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    viewModel.performUndo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(viewModel.undoStack.isEmpty)
                .accessibilityLabel("Undo")
                
                Button {
                    viewModel.performRedo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(viewModel.redoStack.isEmpty)
                .accessibilityLabel("Redo")
                
                if let shareText = shareContent() {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share")
                }
                
                EditButton()
                    .accessibilityLabel(editMode?.wrappedValue == .active ? "Done Editing" : "Edit")
            }
        }
    }
    
    // MARK: - Rhyme Accessory
    @ViewBuilder
    private var rhymeAccessoryBar: some View {
        if !viewModel.suggestedRhymes.isEmpty && focusedLineID != nil {
            VStack(spacing: 0) {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text(viewModel.rhymeTargetWord.isEmpty ? "Rhymes" : "Rhymes for \u{201C}\(viewModel.rhymeTargetWord)\u{201D}")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                            .accessibilityHidden(true)
                        
                        ForEach(viewModel.suggestedRhymes, id: \.self) { rhyme in
                            Button {
                                insertRhyme(rhyme)
                            } label: {
                                Text(rhyme)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.thinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Insert rhyme \(rhyme)")
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
    
    private func shareContent() -> String? {
        guard !viewModel.sections.isEmpty else { return nil }
        let body = viewModel.sections.map { section in
            let header = "[\(section.type.rawValue)]"
            let lines = section.lines.map(\.text).joined(separator: "\n")
            return "\(header)\n\(lines)"
        }.joined(separator: "\n\n")
        return "\(navTitle)\n\n\(body)"
    }
}

// MARK: - Row Subview
struct LyricLineRow: View {
    @Binding var line: LyricLine
    let sectionID: UUID
    @ObservedObject var viewModel: LyricViewModel
    var focusedLineID: FocusState<UUID?>.Binding
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if isInEditMode {
                Text(line.text.isEmpty ? "Empty Line" : line.text)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .accessibilityLabel(line.text.isEmpty ? "Empty line" : line.text)
            } else {
                // axis: .vertical lets the field grow and wrap long lines
                // instead of scrolling the text horizontally out of view.
                // That means Return inserts a literal newline rather than
                // calling onSubmit, so we detect that newline here and turn
                // it into "create the next lyric line" ourselves.
                TextField("Write your bars...", text: $line.text, axis: .vertical)
                    .focused(focusedLineID, equals: line.id)
                    .lineLimit(1...4)
                    .onChange(of: line.text) { newValue in
                        guard newValue.contains("\n") else {
                            viewModel.updateRhymes(for: newValue)
                            return
                        }
                        line.text = newValue.replacingOccurrences(of: "\n", with: "")
                        let newID = viewModel.addNewLine(after: line.id, in: sectionID)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            focusedLineID.wrappedValue = newID
                        }
                    }
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .font(.body)
                    .padding(.vertical, 6)
                    .accessibilityHint("Double tap to edit")
            }
            
            if !isInEditMode {
                syllableBadge(count: line.syllableCount)
            }
        }
        .contentShape(Rectangle())
    }
    
    private var isInEditMode: Bool {
        viewModel.isEditing || false
    }
    
    @ViewBuilder
    private func syllableBadge(count: Int) -> some View {
        let isHigh = count > 12

        Group {
            if isHigh {
                // Only call attention to lines that are unusually long —
                // keeps the editor quiet for normal lines instead of a
                // capsule on every single row.
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                    .foregroundStyle(.orange)
            } else {
                Text("\(count)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .accessibilityLabel("Syllables \(count)")
        .accessibilityHint(isHigh ? "Higher than typical" : "Within typical range")
    }
}

struct LyricView_Previews: PreviewProvider {
    static var previews: some View {
        LyricView()
            .preferredColorScheme(.dark)
    }
}
