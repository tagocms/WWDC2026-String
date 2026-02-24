//
//  Named.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

protocol Named {
    var name: String { get }
}

extension Named {
    /// Filters an array of Named items into another, using the name parameter as the criteria.
    static func filtered<T: Named>(_ items: [T], by name: String) -> [T] {
        let stringComponents = name.split(separator: " ")
        
        var filteredItems: [T] = []
        
        outerLoop: for item in items {
            innerLoop: for component in stringComponents {
                guard item.name.localizedCaseInsensitiveContains(component) else { continue outerLoop }
            }
            filteredItems.append(item)
        }
        
        return filteredItems
    }
}
