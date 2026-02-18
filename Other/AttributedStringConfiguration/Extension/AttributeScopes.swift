//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import Foundation

extension AttributeScopes {
    struct CustomAttributes: AttributeScope {
        let linkedNote: LinkedNoteAttribute
        let tag: TagAttribute
    }
}
