//
//  Note.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class Note: Identifiable, Named {
    // MARK: - Model initializers and properties
    struct Position: Codable {
        var x: Int
        var y: Int
        static let zero = Self(x: 0, y: 0)
        
        func distance(to point: Position) -> Float {
            sqrt(pow(Float(self.x - point.x), 2) + pow(Float(self.y - point.y), 2))
        }
    }
    @Attribute(.unique)
    private(set) var id: UUID
    private(set) var dateCreated: Date
    private(set) var dateLastUpdated: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Tag.notes)
    private(set) var tags: [Tag]
    @Relationship(deleteRule: .nullify, inverse: \Note.backlinks)
    private(set) var linkedNotes: [Note]
    @Relationship(deleteRule: .nullify)
    private(set) var backlinks: [Note] = []
    @Relationship(deleteRule: .nullify)
    private(set) var slipbox: Slipbox
    
    @Attribute(.unique)
    private(set) var name: String
    private(set) var contentBody: AttributedString
    private(set) var position: Position
    
    init(
        id: UUID = UUID(),
        dateCreated: Date = Date.now,
        dateLastUpdated: Date = Date.now,
        tags: [Tag] = [],
        linkedNotes: [Note] = [],
        slipbox: Slipbox,
        title: String,
        contentBody: AttributedString = "",
        position: Position = .zero
    ) {
        self.id = id
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.tags = tags
        self.linkedNotes = linkedNotes
        self.slipbox = slipbox
        self.name = title
        self.contentBody = contentBody
        self.position = position
    }
    
    // MARK: - Setter methods
    func updatePosition(to position: Position) {
        self.position = position
    }
    
    func addLink(to note: Note) {
        self.linkedNotes.append(note)
    }
    
    func removeLink(to note: Note) {
        guard let index = self.linkedNotes.firstIndex(of: note) else { return }
        self.linkedNotes.remove(at: index)
    }
    
    func setName(_ name: String, allNotes: [Note]) {
        if isNameValid(name, allNotes: allNotes) {
            self.name = name
            Note.alterTextInContentBody(self, allNotes: allNotes)
        }
    }
    
    static func alterTextInContentBody(_ alteredNote: Note, allNotes: [Note]) {
        // Example: replace every run whose `linkedNote` equals `alteredNote.id`
        // with the new note name, preserving the run's attributes.
        for note in allNotes {
            guard note.linkedNotes.contains(alteredNote) else { continue }
            var body = note.contentBody
            
            // 1) Collect target ranges and their attributes (don’t mutate while iterating).
            var targets: [(range: Range<AttributedString.Index>, attrs: AttributeContainer)] = []
            for run in body.runs {
                print("Altered Note: \(alteredNote.name) - ID \(alteredNote.id).")
                print("Note to alter: \(note.name) - Attribute ID \(run.linkedNote)")
                if run.linkedNote == alteredNote.id {
                    targets.append((run.range, run.attributes))
                }
            }
            
            // 2) Replace from the end to keep earlier ranges valid.
            for (range, attrs) in targets.reversed() {
                // Create a replacement carrying the same attributes as the original run.
                let replacement = AttributedString(alteredNote.name, attributes: attrs)
                body.replaceSubrange(range, with: replacement)
            }
            
            // 3) Write the mutated value back.
            note.contentBody = body
        }
    }
    
    func setParentSlipbox(_ slipbox: Slipbox) {
        self.slipbox = slipbox
    }
    
    func setTags(_ tags: [Tag]) {
        var tagSet: Set<Tag> = []
        tagSet.formUnion(tags)
        self.tags = tagSet.map { $0 }
    }
    
    func setLinkedNotes(_ linkedNotes: [Note]) {
        var noteSet: Set<Note> = []
        noteSet.formUnion(linkedNotes)
        self.linkedNotes = noteSet.map { $0 }
    }
    
    func setContent(_ contentBody: AttributedString) {
        self.contentBody = contentBody
    }
    
    // MARK: - Auxiliary
    func isNameValid(_ name: String, allNotes: [Note]) -> Bool {
        for note in allNotes {
            if note != self {
                if note.name == name {
                    return false
                }
            }
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        guard name.count <= 80 else {
            return false
        }
        
        return true
    }
}

extension Note: Comparable {
    static func <(lhs: Note, rhs: Note) -> Bool {
        lhs.name < rhs.name
    }
}

extension Note: Equatable {
    static func ==(lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
}
