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
        for range in targets.reversed() {
            body.characters.replaceSubrange(range, with: alteredItem.formatName)
        }
        note.setContent(body)
    }
}

enum AutoFormatableError: Error {
    case itemNotFound(String)
    case itemShouldNotBeChecked(String)
}
