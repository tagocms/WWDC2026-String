//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import Foundation

struct LinkedNoteAttribute: CodableAttributedStringKey {
    typealias Value = Note.ID
    
    static let name = "com.tiago.LinkedNoteAttribute"
}
