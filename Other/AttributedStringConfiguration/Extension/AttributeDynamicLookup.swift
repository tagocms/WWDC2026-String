//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 18/02/26.
//

import Foundation

extension AttributeDynamicLookup {
    /// The subscript for pulling custom attributes into the dynamic attribute lookup.
    ///
    /// This makes them available throughout the code using the name they have in the
    /// `AttributeScopes.CustomAttributes` scope.
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.CustomAttributes, T>
    ) -> T {
        self[T.self]
    }
}
