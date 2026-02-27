//
//  AutoFormatable.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
//

import Foundation

protocol AutoFormatable {
    var formatName: String { get }
}

extension AutoFormatable {
    /// For all notes, check if there is a desynchronization between its content body and its properties (links and tags) and, if there is, corrects it and applies changes to their properties and to the text itself, if necessary (i.e. if the text is lowercased but the name of the item to apply is in uppercase).
    static func synchronizeContentBody<T: AutoFormatable & Identifiable>(
        _ itemToApply: T,
        oldFormattedName: String,
        allNotes: [Note],
        shouldDelete: Bool = false,
        shouldApply: (
            _ noteToCheck: Note,
            _ itemToApply: T
        ) -> Bool,
        applyChange: (
            _ noteToCheck: Note,
            _ itemToApply: T
        ) -> Void,
        shouldAlterText: (
            _ noteToCheck: Note,
            _ alteredItem: T
        ) -> Bool
    ) {
        for note in allNotes {
            do {
                try applyChangesToNoteFromContentBody(itemToApply, note: note, shouldItemBeChecked: shouldApply, changesToMake: applyChange)
                try alterTextInContentBody(
                    itemToApply,
                    for: note,
                    oldFormattedName: oldFormattedName,
                    shouldItemBeChecked: shouldAlterText
                )
            } catch {
                continue
            }
        }
    }
    
    /// Alters the text within content body to reflect the altered item's new state, for all notes in a collection.
    static func alterTextInContentBodyForAllNotes<T: AutoFormatable & Identifiable>(
        _ alteredItem: T,
        oldFormattedName: String,
        allNotes: [Note],
        shouldDelete: Bool = false,
        shouldItemBeChecked: (_ noteToCheck: Note, _ alteredItem: T) -> Bool
    ) {
        for note in allNotes {
            do {
                try alterTextInContentBody(
                    alteredItem,
                    for: note,
                    oldFormattedName: oldFormattedName,
                    shouldDelete: shouldDelete,
                    shouldItemBeChecked: shouldItemBeChecked
                )
            } catch {
                continue
            }
        }
    }
    
    /// Alters the text within content body to reflect the altered item's new state.
    static func alterTextInContentBody<T: AutoFormatable & Identifiable>(
        _ alteredItem: T,
        for note: Note,
        oldFormattedName: String,
        shouldDelete: Bool = false,
        shouldItemBeChecked: (_ noteToCheck: Note, _ alteredItem: T) -> Bool
    ) throws {
        guard shouldItemBeChecked(note, alteredItem) else {
            throw AutoFormatableError.itemShouldNotBeChecked("Item \(note.name) shouldn't be checked.")
        }
        var body = note.contentBody
        let targets: [Range<AttributedString.Index>] = String.ranges(of: AttributedString(oldFormattedName), in: body)
        print(targets)
        for range in targets.reversed() {
            if shouldDelete {
                print("DELETE: ", alteredItem.formatName)
            } else {
                print(alteredItem.formatName)
            }
            body.characters.replaceSubrange(range, with: shouldDelete ? "" : alteredItem.formatName)
        }
        note.setContent(body)
    }
    
    /// Applies changes made within each note's content body to its other properties.
    static func applyChangesToAllNotesFromContentBody<T: AutoFormatable & Identifiable>(
        _ itemToApply: T,
        allNotes: [Note],
        shouldItemBeChecked: (
            _ noteToCheck: Note,
            _ itemToApply: T
        ) -> Bool,
        changesToMake: (
            _ noteToCheck: Note,
            _ itemToApply: T
        ) -> Void
    ) {
        for note in allNotes {
            do {
                try applyChangesToNoteFromContentBody(
                    itemToApply,
                    note: note,
                    shouldItemBeChecked: shouldItemBeChecked,
                    changesToMake: changesToMake
                )
            } catch {
                continue
            }
        }
    }
    
    /// Applies changes made within a note's content body to its other properties.
    static func applyChangesToNoteFromContentBody<T: AutoFormatable & Identifiable>(
        _ itemToApply: T,
        note: Note,
        shouldItemBeChecked: (
            _ noteToCheck: Note,
            _ itemToApply: T
        ) -> Bool,
        changesToMake: (
            _ noteToCheck: Note,
            _ itemToApply: T
        ) -> Void
    ) throws {
        guard shouldItemBeChecked(note, itemToApply),
              !String.ranges(of: AttributedString(itemToApply.formatName), in: note.contentBody).isEmpty else {
            throw AutoFormatableError.itemShouldNotBeChecked("Item \(note.name) should not be checked.")
        }
        changesToMake(note, itemToApply)
    }
}

enum AutoFormatableError: Error {
    case itemNotFound(String)
    case itemShouldNotBeChecked(String)
}
