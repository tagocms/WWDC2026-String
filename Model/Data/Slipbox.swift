//
//  Slipbox.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import Foundation
import SwiftData

@Model
final class Slipbox: Identifiable, Named {
    // MARK: - Stored properties
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
    
    // MARK: - Computed properties
    var totalNoteCount: Int {
        var noteCount = notes.count
        for slipbox in slipboxes {
            noteCount += slipbox.totalNoteCount
        }
        return noteCount
    }
    
    init(dateCreated: Date = Date.now, dateLastUpdated: Date = Date.now, title: String) {
        self.dateCreated = dateCreated
        self.dateLastUpdated = dateLastUpdated
        self.name = title
    }
    
    // MARK: - Setters
    func setName(_ name: String) {
        if Self.isNameValid(name) {
            self.name = name
        }
    }
    
    func setParentSlipbox(_ slipbox: Slipbox?) {
        self.parentSlipbox = slipbox
    }
    
    // MARK: - Static
    static func isNameValid(_ name: String) -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "root" else {
            return false
        }
        return true
    }
}

extension Slipbox: Comparable {
    static func < (lhs: Slipbox, rhs: Slipbox) -> Bool {
        lhs.name < rhs.name
    }
}
