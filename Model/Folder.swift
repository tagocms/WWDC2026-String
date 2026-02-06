//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class Folder: Identifiable {
    var dateCreated: Date
    var dateLastUpdated: Date
    @Relationship(deleteRule: .cascade)
    var notes: [Note]
    var title: String
    
    init(dateCreated: Date = Date.now, dateLastUpdated: Date = Date.now, notes: [Note], title: String) {
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.notes = notes
        self.title = title
    }
}
