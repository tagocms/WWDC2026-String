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

extension Note: AutoFormatable {
    /// Variable used to standardize link formatting
    var formatName: String {
        return "/\(name)/"
    }
}

extension Note: StandardFetchable {
    static let fetchDescriptor: FetchDescriptor<Note> = FetchDescriptor(sortBy: [SortDescriptor(\.name, order: .forward)])
}

// MARK: - Setter methods
extension Note {
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
            let oldName = self.formatName
            self.name = name
            
            var container = AttributeContainer()
            container.linkedNote = self.id
            Note.alterTextInContentBodyForAllNotes(self, oldFormattedName: oldName, allNotes: allNotes, attributes: container) { noteToCheck, alteredItem in
                noteToCheck.linkedNotes.contains(alteredItem)
            }

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
}

// MARK: - Auxiliary methods
extension Note {
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
