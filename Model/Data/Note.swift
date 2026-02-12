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
    private(set) var contentBody: String
    private(set) var position: Position

    init(
        dateCreated: Date = Date.now,
        dateLastUpdated: Date = Date.now,
        tags: [Tag] = [],
        linkedNotes: [Note] = [],
        slipbox: Slipbox,
        title: String,
        contentBody: String = "",
        position: Position = .zero
    ) {
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
