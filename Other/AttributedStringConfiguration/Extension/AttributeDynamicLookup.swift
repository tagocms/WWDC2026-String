//
//  AttributeDynamicLookup.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import Foundation

extension AttributeDynamicLookup {
    /// The subscript for pulling custom attributes into the dynamic attribute lookup.
    /// This code was provided by Apple in their "Code-along: Cook up a rich text experience in SwiftUI with AttributedString" WWDC25 video.
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.CustomAttributes, T>
    ) -> T {
        self[T.self]
    }
}
