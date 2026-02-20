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
        attributes: AttributeContainer,
        shouldItemBeChecked: (_ noteToCheck: Note, _ alteredItem: T) -> Bool
    ) {
        for note in allNotes {
            guard shouldItemBeChecked(note, alteredItem) else { continue }
            var body = note.contentBody
            let targets = body.characters.ranges(of: AttributedString(oldFormattedName).characters)
            for range in targets.reversed() {
                let replacement = AttributedString(shouldDelete ? "" : alteredItem.formatName, attributes: attributes)
                body.replaceSubrange(range, with: replacement)
            }
            note.setContent(body)
        }
    }
}
