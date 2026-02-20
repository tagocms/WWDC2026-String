//
//  StandardFetchable.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 20/02/26.
//

import SwiftData

protocol StandardFetchable {
    associatedtype Model: PersistentModel
    /// Variable used for querying into SwiftData's model context
    static var fetchDescriptor: FetchDescriptor<Model> { get }
}
