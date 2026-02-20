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
    static func alterTextInContentBodyForAllNotes<T: AutoFormatable & Identifiable>(_ alteredItem: T, allNotes: [Note], shouldItemBeChecked: (_ noteToCheck: Note, _ alteredItem: T) -> Bool, shouldRunBeChanged: (_ runToCheck: AttributedString.Runs.Element, _ alteredItem: T) -> Bool, shouldDelete: Bool = false) {
        for note in allNotes {
            guard shouldItemBeChecked(note, alteredItem) else { continue }
            var body = note.contentBody
            
            var targets: [(range: Range<AttributedString.Index>, attrs: AttributeContainer)] = []
            for run in body.runs {
                if shouldRunBeChanged(run, alteredItem) {
                    targets.append((run.range, run.attributes))
                }
            }
            
            for (range, attributes) in targets.reversed() {
                let replacement = AttributedString(shouldDelete ? "" : alteredItem.formatName, attributes: attributes)
                body.replaceSubrange(range, with: replacement)
            }
            
            note.setContent(body)
        }
    }
}
