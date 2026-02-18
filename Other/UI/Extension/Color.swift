//
//  Color.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

extension Color {
    /// Initializes a Color from a codable HexColor format
    public init(from hexColor: HexColor) {
        self.init(uiColor: UIColor(from: hexColor))
    }
    
    /// Converts a Color to a HexColor
    func toHexColor() -> HexColor {
        UIColor(self).toHexColor()
    }
    
    /// Color used for the mainView's background.
    static let appBackground: Color = Color(
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                UIColor(from: HexColor.black)
            default:
                UIColor(from: HexColor.white)
            }
        }
    )
}

extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .black
            return
        }
        
        do {
            if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
                self = Color(color)
            } else {
                self = .black
            }
        } catch {
            self = .black
        }
    }
    
    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false) as Data
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}
