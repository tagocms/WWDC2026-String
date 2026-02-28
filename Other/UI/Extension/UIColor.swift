//
//  UIColor.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import UIKit

extension UIColor {
    /// Initializes a UIColor from a codable HexColor format
    convenience init(from hexColor: HexColor) {
        self.init(
            red: max(CGFloat(min(hexColor.red, 255)) / 255, 0),
            green: max(CGFloat(min(hexColor.green, 255)) / 255, 0),
            blue: max(CGFloat(min(hexColor.blue, 255)) / 255, 0),
            alpha: max(CGFloat(min(hexColor.alpha, 255)) / 255, 0)
        )
    }
    
    /// Converts a UIColor to a HexColor
    func toHexColor() -> HexColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return HexColor(red: Int(red * 0xFF), green: Int(green * 0xFF), blue: Int(blue * 0xFF), alpha: Int(alpha * 0xFF))
    }
}
