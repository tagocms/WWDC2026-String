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
    func setName(_ name: String, allSlipboxes: [Slipbox]) {
        if isNameValid(name, allSlipboxes: allSlipboxes) {
            self.name = name
        }
    }
    
    func setParentSlipbox(_ slipbox: Slipbox?) {
        // TODO: VALIDATE IF THERE ARE NO CIRCULAR REFERENCES
        if isParentSlipboxValid(slipbox) {
            self.parentSlipbox = slipbox
        }
    }
    
    // MARK: - Auxiliary
    func isParentSlipboxValid(_ newParentSlipbox: Slipbox?, originalSlipbox: Slipbox? = nil) -> Bool {
        guard let newParentSlipbox else { return true }
        guard newParentSlipbox !== self else { return false }
        guard newParentSlipbox !== originalSlipbox else { return false }
        
        return newParentSlipbox.isParentSlipboxValid(newParentSlipbox.parentSlipbox, originalSlipbox: originalSlipbox == nil ? self : originalSlipbox)
    }
    
    func isNameValid(_ name: String, allSlipboxes: [Slipbox]) -> Bool {
        for slipbox in allSlipboxes {
            if slipbox != self {
                if slipbox.name == name {
                    return false
                }
            }
        }
        
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
