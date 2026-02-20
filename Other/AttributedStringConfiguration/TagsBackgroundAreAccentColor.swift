//
//  TagsBackgroundAreAccentColor.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
//

import Foundation
import SwiftUI

struct TagsBackgroundAreAccentColor: AttributedTextValueConstraint {
    typealias AttributeKey = AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute
    typealias Scope = NoteFormattingDefinition.Scope
    
    func constrain(_ container: inout Attributes) {
        if container.tag != nil {
            container.backgroundColor = .accentColor.opacity(0.2)
        } else {
            container.backgroundColor = nil
            // TODO: - Decidir como vai ficar
//            if container.foregroundColor == .accentColor {
//                container.foregroundColor = nil
//            }
        }
    }
}
