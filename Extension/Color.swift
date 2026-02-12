//
//  Color.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

extension Color {
    /// Color used for the mainView's background.
    static let appBackground: Color = Color(
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                UIColor(red: 0x00, green: 0x00, blue: 0x00)
            default:
                UIColor(red: 0xFF, green: 0xFF, blue: 0xFF)
            }
        }
    )
}
