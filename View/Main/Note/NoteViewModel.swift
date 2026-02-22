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
        get { note.tags.sorted() }
        set { note.setTags(newValue) }
    }
    var selectedNoteLinkedNotes: [Note] {
        get { note.linkedNotes.sorted() }
        set { note.setLinkedNotes(newValue) }
    }
    var selectedNoteContentBody: AttributedString {
        get { note.contentBody }
        set { note.setContent(newValue) }
    }
    
    var newTagName: String = ""
    var filteredTags: [Tag] { Note.filtered(tags, by: newTagName) }
    
    var newLinkedNoteName: String = ""
    var filteredLinkedNotes: [Note] {
        Note.filtered(notes, by: newLinkedNoteName).filter { $0 !== note }
    }
    
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
    
    /// Creates and adds a new note to the selected note's linked notes.
    func createAndAddNoteToLinkedNotes() {
        selectedNoteLinkedNotes.append(createAndReturnNewNote(with: newLinkedNoteName, shouldAutoOpen: false))
        newLinkedNoteName = ""
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
    
    /// Checks if the newLinkedNoteName is valid.
    func isNewLinkedNoteNameValid() -> Bool {
        Note.isNewNameValid(newLinkedNoteName, allNotes: notes)
    }
}
