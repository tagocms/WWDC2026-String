//
//  Tag.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import SwiftData

@Model
final class Tag: Identifiable, Named {
    @Attribute(.unique)
    private(set) var name: String
    
    @Relationship(deleteRule: .nullify,)
    private(set) var notes: [Note] = []
    
    init(name: String) {
        self.name = name
    }
}

extension Tag: Comparable {
    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.name < rhs.name
    }
}
