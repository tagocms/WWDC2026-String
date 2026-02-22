//
//  LinkedNotesAndTagsAreAccentColor.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
//

import Foundation
import SwiftUI

struct LinkedNotesAndTagsAreAccentColor: AttributedTextValueConstraint {
    typealias AttributeKey = AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
    typealias Scope = NoteFormattingDefinition.Scope
    
    func constrain(_ container: inout Attributes) {
        if container.linkedNote != nil || container.tag != nil {
            container.foregroundColor = .accentColor
        } else {
            container.foregroundColor = nil
        }
    }
}
