//
//  LinkedNotesShouldBeLinked.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import SwiftUI

struct LinkedNotesShouldBeLinked: AttributedTextValueConstraint {
    typealias AttributeKey = AttributeScopes.FoundationAttributes.LinkAttribute
    typealias Scope = NoteFormattingDefinition.Scope
    
    func constrain(_ container: inout Attributes) {
        guard let linkedNote = container.linkedNote else {
            container.link = nil
            return
        }
        container.link = URL.createDeepLinkURL(data: linkedNote)
    }
}
