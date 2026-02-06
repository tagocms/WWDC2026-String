//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import SwiftData

@Model
final class Tag: Identifiable {
    @Attribute(.unique)
    var title: String
    @Relationship(deleteRule: .nullify)
    var notes: [Note]
    
    init(title: String, notes: [Note]) {
        self.title = title
        self.notes = notes
    }
}
