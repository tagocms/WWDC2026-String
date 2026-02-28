//
//  NoteFormattingDefinition.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import SwiftUI

struct NoteFormattingDefinition: AttributedTextFormattingDefinition {
    struct Scope: AttributeScope {
        let swiftUI: AttributeScopes.SwiftUIAttributes
        let tag: TagAttribute
        let linkedNote: LinkedNoteAttribute
    }
    
    var body: some AttributedTextFormattingDefinition<Scope> {
        LinkedNotesAndTagsAreAccentColor()
        LinkedNotesShouldBeLinked()
        TagsBackgroundAreAccentColor()
    }
}
