//
//  NoteViewModel.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 20/02/26.
//

import SwiftData
import SwiftUI

@Observable
@MainActor
final class NoteViewModel: MainViewModel {
    // MARK: - Data and UI State
    let note: Note
    var selectedNoteName: String {
        get { note.name }
        set { note.setNameAndUpdateAllNotes(newValue, allNotes: notes) }
    }
    var selectedNoteParentSlipbox: Slipbox {
        get { note.slipbox }
        set { note.setParentSlipbox(newValue) }
    }
    var selectedNoteTags: [Tag] {
        get { note.tags }
        set { note.setTags(newValue) }
    }
    var selectedNoteLinkedNotes: [Note] {
        get { note.linkedNotes }
        set { note.setLinkedNotes(newValue) }
    }
    var selectedNoteContentBody: AttributedString {
        get { note.contentBody }
        set { note.setContent(newValue) }
    }
    var newTagName: String = ""
    var filteredTags: [Tag] { Note.filtered(tags, by: newTagName) }
    
    // MARK: - Initializer
    init(_ modelContext: ModelContext, note: Note) {
        self.note = note
        super.init(modelContext)
    }
    
    @MainActor
    deinit {
        try? modelContext.save()
    }
    
    // MARK: - Intent functions
    /// Creates a new tag and appends it to the selected note, while also resetting the newTagName variable.
    func createNewTagAndAddToSelectedNote() {
        guard let newTag = createAndReturnNewTag(name: newTagName) else {
            return
        }
        selectedNoteTags.append(newTag)
        newTagName = ""
    }
    
    /// Adds the tag to the selected note.
    func addTagToNote(_ tag: Tag) {
        selectedNoteTags.append(tag)
        newTagName = ""
    }
    
    /// Checks if the newTagName is valid.
    func isNewTagNameValid() -> Bool {
        Tag.isNameValid(newTagName, allTags: tags)
    }
}
