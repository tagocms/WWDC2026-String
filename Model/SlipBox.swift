//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class SlipBox: Identifiable {
    var dateCreated: Date
    var dateLastUpdated: Date
    
    @Relationship(deleteRule: .nullify)
    var parentSlipBox: SlipBox? = nil
    @Relationship(deleteRule: .cascade, inverse: \SlipBox.parentSlipBox)
    var slipboxes: [SlipBox] = []
    @Relationship(deleteRule: .cascade, inverse: \Note.slipBox)
    var notes: [Note] = []
    
    var title: String
    
    init(dateCreated: Date = Date.now, dateLastUpdated: Date = Date.now, title: String) {
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.title = title
    }
}
