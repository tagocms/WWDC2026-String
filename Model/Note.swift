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
    
    var title: String
    var contentBody: String
    
    init(dateCreated: Date = Date.now, dateLastUpdated: Date = Date.now, tags: [Tag], linkedNotes: [Note], slipbox: Slipbox, title: String, contentBody: String) {
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.tags = tags
        self.linkedNotes = linkedNotes
        self.slipbox = slipbox
        self.title = title
        self.contentBody = contentBody
    }
}
