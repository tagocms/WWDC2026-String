//
//  NoteFormattingDefinition.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import SwiftUI

struct NoteFormattingDefinition: AttributedTextFormattingDefinition {
    struct Scope: AttributeScope {
        let adaptiveImageGlyph: AttributeScopes.SwiftUIAttributes.AdaptiveImageGlyphAttribute
        let backgroundColor: AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute
        let baselineOffset: AttributeScopes.SwiftUIAttributes.BaselineOffsetAttribute
        let decodingConfiguration: AttributeScopes.SwiftUIAttributes.DecodingConfiguration
        let encodingConfiguration: AttributeScopes.SwiftUIAttributes.EncodingConfiguration
        let font: AttributeScopes.SwiftUIAttributes.FontAttribute
        let foregroundColor: AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
        let kerning: AttributeScopes.SwiftUIAttributes.KerningAttribute
        let strikethroughStyle: AttributeScopes.SwiftUIAttributes.StrikethroughStyleAttribute
        let tracking: AttributeScopes.SwiftUIAttributes.TrackingAttribute
        let underline: AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute
        let link: AttributeScopes.FoundationAttributes.LinkAttribute
        let writingDirection: AttributeScopes.FoundationAttributes.WritingDirectionAttribute
        let textAlignment: AttributeScopes.CoreTextAttributes.TextAlignmentAttribute
        let tag: TagAttribute
        let linkedNote: LinkedNoteAttribute
    }
    
    var body: some AttributedTextFormattingDefinition<Scope> {
        LinkedNotesAreTintColor()
    }
}
