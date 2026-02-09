//
//  Note.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class Note: Identifiable {
    struct Position: Codable {
        var x: Int
        var y: Int
        static let zero = Self(x: 0, y: 0)
    }
    
    var dateCreated: Date
    var dateLastUpdated: Date

    @Relationship(deleteRule: .nullify, inverse: \Tag.notes)
    var tags: [Tag]
    @Relationship(deleteRule: .nullify, inverse: \Note.backlinks)
    var linkedNotes: [Note]
    @Relationship(deleteRule: .nullify)
    var backlinks: [Note] = []
    @Relationship(deleteRule: .nullify)
    var slipbox: Slipbox
    
    @Attribute(.unique)
    var name: String
    var contentBody: String
    var position: Position

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
}
