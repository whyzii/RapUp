//
//  LyricViewModel.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 09/12/25.
//

import SwiftUI
import Combine

class LyricViewModel: ObservableObject {
    @Published var sections: [LyricSection]
    @Published var suggestedRhymes: [String] = []
    @Published var rhymeTargetWord: String = ""
    @Published var isEditing: Bool = false
    
    // Undo/Redo history
    @Published var undoStack: [[LyricSection]] = []
    @Published var redoStack: [[LyricSection]] = []
    
    init() {
        self.sections = [
            LyricSection(type: .verse, lines: [
                LyricLine(text: "Footsteps echo in the summer rain")
            ]),
            LyricSection(type: .chorus, lines: [
                LyricLine(text: "Hold me under, wash away the pain")
            ])
        ]
    }
    
    // MARK: - History
    
    // Save the current state so we can undo FROM it (call BEFORE mutation).
    func saveStateForUndo() {
        // Avoid pushing duplicates
        if let last = undoStack.last, last == sections { return }
        // Limit history size
        if undoStack.count >= 50 { undoStack.removeFirst(undoStack.count - 49) }
        undoStack.append(sections)
        // Any new forward change invalidates redo history
        redoStack.removeAll()
    }
    
    func performUndo() {
        guard let previous = undoStack.popLast() else { return }
        // Current state becomes redo candidate
        redoStack.append(sections)
        withAnimation {
            sections = previous
        }
    }
    
    func performRedo() {
        guard let next = redoStack.popLast() else { return }
        // Current state becomes undo candidate
        undoStack.append(sections)
        withAnimation {
            sections = next
        }
    }
    
    // MARK: - Section Management
    
    func addSection(type: SectionType) {
        saveStateForUndo()
        let newSection = LyricSection(type: type, lines: [LyricLine(text: "")])
        withAnimation { sections.append(newSection) }
    }
    
    func deleteSection(_ section: LyricSection) {
        saveStateForUndo()
        withAnimation { sections.removeAll { $0.id == section.id } }
    }
    
    func duplicateSection(_ section: LyricSection) {
        saveStateForUndo()
        let newLines = section.lines.map { LyricLine(text: $0.text) }
        let newSection = LyricSection(type: section.type, lines: newLines)
        
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            withAnimation {
                sections.insert(newSection, at: index + 1)
            }
        }
    }
    
    func duplicateSectionAtEnd(_ section: LyricSection) {
        saveStateForUndo()
        let newLines = section.lines.map { LyricLine(text: $0.text) }
        let newSection = LyricSection(type: section.type, lines: newLines)
        withAnimation {
            sections.append(newSection)
        }
    }
    
    func moveSection(from source: IndexSet, to destination: Int) {
        // Make reordering undoable like Notes
        saveStateForUndo()
        sections.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Line Management
    
    @discardableResult
    func addNewLine(after lineID: UUID, in sectionID: UUID) -> UUID? {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionID }),
              let lineIndex = sections[sectionIndex].lines.firstIndex(where: { $0.id == lineID }) else { return nil }
        // Optional: make adding a new blank line undoable. Comment out if you don't want it.
        saveStateForUndo()
        let newLine = LyricLine(text: "")
        sections[sectionIndex].lines.insert(newLine, at: lineIndex + 1)
        return newLine.id
    }
    
    func deleteLine(lineID: UUID, fromSectionID: UUID) {
        saveStateForUndo()
        if let sIndex = sections.firstIndex(where: { $0.id == fromSectionID }) {
            withAnimation {
                sections[sIndex].lines.removeAll { $0.id == lineID }
            }
        }
    }

    func duplicateLine(line: LyricLine, in sectionID: UUID) {
        saveStateForUndo()
        if let sIndex = sections.firstIndex(where: { $0.id == sectionID }),
           let lIndex = sections[sIndex].lines.firstIndex(where: { $0.id == line.id }) {
            
            let copy = LyricLine(text: line.text)
            withAnimation {
                sections[sIndex].lines.insert(copy, at: lIndex + 1)
            }
        }
    }
    
    func moveLine(from source: IndexSet, to destination: Int, in section: LyricSection) {
        if let sectionIndex = sections.firstIndex(where: { $0.id == section.id }) {
            // Make line reordering undoable like Notes
            saveStateForUndo()
            sections[sectionIndex].lines.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    // MARK: - Utils
    
    func copyLineText(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    // MARK: - Rhymes
    func updateRhymes(for text: String) {
        let lastWord = text.components(separatedBy: " ").last?
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters) ?? ""

        rhymeTargetWord = lastWord

        switch lastWord {
        case "rain": suggestedRhymes = ["pain", "insane", "vein", "plain", "brain"]
        case "gold": suggestedRhymes = ["bold", "cold", "fold", "mold", "old", "told"]
        case "explain": suggestedRhymes = ["rain", "remain", "sustain", "train"]
        case "pain": suggestedRhymes = ["rain", "chain", "drain", "gain"]
        default: suggestedRhymes = []
        }
    }
}

