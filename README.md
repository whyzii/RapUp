# RapUP — Lyrics Editor

A focused iOS app for songwriters. RapUP organizes your lyrics into a clean library, lets you structure songs section by section, and counts syllables per line as you write.

---

## Key Features

**Library**
- All your lyrics in one place, with search and three sort modes (recently updated, title A–Z, recently created)
- Organize into folders — delete a folder and its lyrics stay, never lost
- Bookmark favorites; access them in a dedicated Bookmarks view
- Trash with soft-delete and permanent-delete; empty trash in one tap
- Swipe actions (bookmark, delete, rename, share) and a long-press context menu on every lyric

**Editor**
- Structure songs with named sections — Verse, Chorus, Bridge, Intro, Outro
- Collapse/expand individual sections to focus on what you're working on
- Reorder sections and lines with drag-and-drop
- Duplicate a section in place or append it to the end
- Undo/redo stack (up to 50 states) accessible right from the toolbar
- Auto-titles a lyric from its first line the moment you start writing
- Share the full formatted lyric (section headers + lines) via the system share sheet

**Rhymes**
- A scrollable rhyme tray appears above the keyboard whenever a line has focus
- Tap any suggestion to append it to the current line instantly

**Syllable counter**
- Each line automatically counts its syllables (vowel-group algorithm with silent-e handling), available from the model without any extra UI overhead

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| UIKit bridge | `UIActivityViewController` via `UIViewControllerRepresentable` |
| Reactive state | Combine (`@Published`, `ObservableObject`) |
| Persistence | JSON file in the app's Documents directory (`library.json`) |
| Architecture | MVVM — `LibraryViewModel` owns the library; `LyricViewModel` owns in-editor state |
| Haptics | Custom `HapticManager` wrapper around `UIImpactFeedbackGenerator` |

No third-party dependencies. No CoreData. No network calls.

---

## Architecture

```
writeV1/
├── Model/
│   ├── LyricModel.swift        # LyricLine (+ syllable counter), LyricSection, SectionType
│   └── LibraryModels.swift     # LyricFolder, LyricDocument, LibraryData
├── ViewModel/
│   ├── LibraryViewModel.swift  # CRUD, search, sort, bookmarks, trash, persistence
│   └── LyricViewModel.swift    # Section/line edits, undo/redo, rhyme suggestions
├── View/
│   ├── LibraryView.swift       # Root list: folders, all lyrics, bookmarks, trash
│   ├── FolderDetailView.swift  # Per-folder lyric list
│   ├── LyricEditorView.swift   # Section/line editor, rhyme tray, toolbar
│   ├── LyricView.swift         # Read-only lyric display
│   ├── BookmarksView.swift     # Filtered bookmark list
│   ├── TrashView.swift         # Restore / permanent-delete
│   └── LiquidGlassButtonStyle.swift  # Custom button style
├── Service/
│   ├── LibraryPersistence.swift  # Encode/decode LibraryData ↔ JSON
│   └── HapticManager.swift       # Shared haptic feedback
└── writeV1/
    ├── writeV1App.swift          # @main entry point
    └── ContentView.swift         # Root tab/navigation host
```

---

## Requirements

- Xcode 15+
- iOS 17+
- No API keys or configuration needed — open and run

---

## Getting Started

```bash
git clone <repo-url>
open "writeV1.xcodeproj"
```

Select a simulator or device running iOS 17+ and hit Run. All data persists locally to the device's Documents directory.
