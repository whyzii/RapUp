//
//  LyricModel.swift
//  writeV1
//
//  Created by Yousefzadeh Abbas on 09/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

// 1. SectionType
enum SectionType: String, CaseIterable, Codable, Equatable {
    case verse = "Verse"
    case chorus = "Chorus"
    case bridge = "Bridge"
    case intro = "Intro"
    case outro = "Outro"

    /// A small, distinct system color per section type so a song's structure
    /// can be scanned at a glance. Uses system colors so it adapts
    /// automatically across light/dark mode.
    var color: Color {
        switch self {
        case .verse: return .blue
        case .chorus: return .orange
        case .bridge: return .purple
        case .intro: return .teal
        case .outro: return .pink
        }
    }
}

// 2. LyricLine (With Smart Syllable Counter)
struct LyricLine: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    
    // This calculates the number automatically whenever 'text' changes
    var syllableCount: Int {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return 0
        }
        
        // 1. Clean the text (remove punctuation)
        let cleanText = text.lowercased().unicodeScalars.map {
            CharacterSet.punctuationCharacters.contains($0) ? " " : String($0)
        }.joined()
        
        let words = cleanText.components(separatedBy: .whitespaces)
        var total = 0
        
        for word in words where !word.isEmpty {
            total += countSyllables(in: word)
        }
        return total
    }
    
    // Helper function to count syllables in one word
    private func countSyllables(in word: String) -> Int {
        let vowels = "aeiouy"
        var currentWord = word
        
        // Rule: Remove silent 'e' at end (like "Time")
        if currentWord.hasSuffix("e") && currentWord.count > 2 && !currentWord.hasSuffix("le") {
            currentWord.removeLast()
        }
        
        // Rule: Count vowel groups (so "ai" in "Rain" counts as 1, not 2)
        var vowelGroups = 0
        var prevWasVowel = false
        
        for char in currentWord {
            if vowels.contains(char) {
                if !prevWasVowel {
                    vowelGroups += 1
                }
                prevWasVowel = true
            } else {
                prevWasVowel = false
            }
        }
        
        // Every word has at least 1 syllable
        return max(1, vowelGroups)
    }
}

// 3. LyricSection
struct LyricSection: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: SectionType
    var lines: [LyricLine]
    var isCollapsed: Bool = false
    
    // Content-based equality: ignore 'id'
    static func == (lhs: LyricSection, rhs: LyricSection) -> Bool {
        lhs.type == rhs.type &&
        lhs.lines == rhs.lines &&
        lhs.isCollapsed == rhs.isCollapsed
    }
}
