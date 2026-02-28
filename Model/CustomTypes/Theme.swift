//
//  Theme.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

enum Theme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
                .light
        case .dark:
                .dark
        }
    }
}
