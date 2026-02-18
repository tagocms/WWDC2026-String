//
//  VerticalAlignment.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 17/02/26.
//

import SwiftUI

extension VerticalAlignment {
    enum DockBarLastTextBaseline: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.lastTextBaseline]
        }
    }
    
    enum SearchBarBottom: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.bottom]
        }
    }
    
    static let dockBarLastTextBaseline = VerticalAlignment(DockBarLastTextBaseline.self)
    static let searchBarBottom = VerticalAlignment(SearchBarBottom.self)
}
