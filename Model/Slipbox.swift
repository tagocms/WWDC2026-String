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
    var dateCreated: Date
    var dateLastUpdated: Date
    
    @Relationship(deleteRule: .nullify)
    var parentSlipbox: Slipbox? = nil
    @Relationship(deleteRule: .cascade, inverse: \Slipbox.parentSlipbox)
    var slipboxes: [Slipbox] = []
    @Relationship(deleteRule: .cascade, inverse: \Note.slipbox)
    var notes: [Note] = []
    
    var name: String
    
    init(dateCreated: Date = Date.now, dateLastUpdated: Date = Date.now, title: String) {
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.name = title
    }
}
