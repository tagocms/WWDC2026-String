//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import Foundation

struct TagAttribute: CodableAttributedStringKey {
    typealias Value = Tag.ID
    
    static let name = "com.tiago.TagAttribute"
}
