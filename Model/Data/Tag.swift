//
//  Tag.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class Tag: Identifiable, Named {
    // MARK: - Stored properties
    @Attribute(.unique)
    private(set) var id: UUID
    @Attribute(.unique)
    private(set) var name: String
    
    @Relationship(deleteRule: .nullify,)
    private(set) var notes: [Note] = []
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag: Comparable {
    static func < (lhs: Tag, rhs: Tag) -> Bool {
        lhs.name < rhs.name
    }
}

extension Tag: AutoFormatable {
    /// Variable used to standardize tag formatting
    var formatName: String {
        return "#\(name)"
    }
}

extension Tag: StandardFetchable {
    static let fetchDescriptor: FetchDescriptor<Tag> = FetchDescriptor(sortBy: [SortDescriptor(\.name, order: .forward)])
}



// MARK: - Auxiliary methods
extension Tag {
    static func isNameValid(_ tagName: String, allTags: [Tag]) -> Bool {
        for tag in allTags {
            if tag.name == tagName {
                return false
            }
        }
        
        guard !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !tagName.contains(" "),
              tagName.count <= 16 else {
            return false
        }
        
        return true
    }
}
