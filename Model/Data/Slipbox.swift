//
//  Slipbox.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class Slipbox: Identifiable {
    private(set) var dateCreated: Date
    private(set) var dateLastUpdated: Date
    
    @Relationship(deleteRule: .nullify)
    private(set) var parentSlipbox: Slipbox? = nil
    @Relationship(deleteRule: .cascade, inverse: \Slipbox.parentSlipbox)
    private(set) var slipboxes: [Slipbox] = []
    @Relationship(deleteRule: .cascade, inverse: \Note.slipbox)
    private(set) var notes: [Note] = []
    
    @Attribute(.unique)
    private(set) var name: String
    
    init(dateCreated: Date = Date.now, dateLastUpdated: Date = Date.now, title: String) {
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.name = title
    }
}

extension Slipbox: Comparable {
    static func < (lhs: Slipbox, rhs: Slipbox) -> Bool {
        lhs.name < rhs.name
    }
}
