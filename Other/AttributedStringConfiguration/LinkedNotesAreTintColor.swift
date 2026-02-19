//
//  LinkedNotesAreTintColor.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import SwiftUI

struct LinkedNotesAreTintColor: AttributedTextValueConstraint {
    typealias AttributeKey = AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
    typealias Scope = NoteFormattingDefinition.Scope
    
    func constrain(_ container: inout Attributes) {
        if container.linkedNote != nil {
            // TODO: - Adicionar links para outras NoteView dentro das LinkedNotes
            container.foregroundColor = .accentColor
        } else {
            container.foregroundColor = nil
        }
    }
}
