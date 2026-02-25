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
    @Attribute(.unique)
    private(set) var id: UUID
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
    /// Returns the total note count inside the slipbox and its child-slipboxes.
    var totalNoteCount: Int {
        var noteCount = notes.count
        for slipbox in slipboxes {
            noteCount += slipbox.totalNoteCount
        }
        return noteCount
    }
    
    init(
        id: UUID = UUID(),
        dateCreated: Date = Date.now,
        dateLastUpdated: Date = Date.now,
        title: String
    ) {
        self.id = id
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

extension Slipbox: Equatable {
    static func == (lhs: Slipbox, rhs: Slipbox) -> Bool {
        lhs.id == rhs.id
    }
}

extension Slipbox: StandardFetchable {
    static let fetchDescriptor: FetchDescriptor<Slipbox> = FetchDescriptor(sortBy: [SortDescriptor(\.name, order: .forward)])
}

// MARK: - Setter methods
extension Slipbox {
    func setName(_ name: String, allSlipboxes: [Slipbox]) {
        let newName = String(name.trimmingPrefix(" "))
        if isNameForSelfValid(newName, allSlipboxes: allSlipboxes) {
            self.name = newName
            self.dateLastUpdated = .now
        }
    }
    
    func setParentSlipbox(_ slipbox: Slipbox?) {
        if isParentSlipboxValid(slipbox) {
            self.parentSlipbox = slipbox
            self.dateLastUpdated = .now
        }
    }
}

// MARK: - Auxiliary methods
extension Slipbox {
    /// Recursive method that verifies if it is possible for a slipbox to have a specific newParentSlipbox.
    func isParentSlipboxValid(_ newParentSlipbox: Slipbox?, originalSlipbox: Slipbox? = nil) -> Bool {
        guard let newParentSlipbox else { return true }
        guard newParentSlipbox != self else { return false }
        guard newParentSlipbox != originalSlipbox else { return false }
        
        return newParentSlipbox.isParentSlipboxValid(newParentSlipbox.parentSlipbox, originalSlipbox: originalSlipbox == nil ? self : originalSlipbox)
    }
    
    func isNameForSelfValid(_ name: String, allSlipboxes: [Slipbox]) -> Bool {
        for slipbox in allSlipboxes {
            if slipbox != self {
                if slipbox.name.lowercased() == name.lowercased() {
                    return false
                }
            }
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "root" else {
            return false
        }
        
        guard name.count <= 30 else {
            return false
        }
        
        guard !name.hasPrefix(" ") else {
            return false
        }
        
        return true
    }
    
    /// Children array for the Outline Group View in SwiftUI.
    var outlineChildren: [Slipbox]? {
        slipboxes.isEmpty ? nil : slipboxes
    }
}
