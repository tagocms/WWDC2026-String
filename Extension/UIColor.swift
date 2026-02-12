//
//  UIColor.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: Int? = nil) {
        self.init(
            red: max(CGFloat(min(red, 255)) / 255, 0),
            green: max(CGFloat(min(green, 255)) / 255, 0),
            blue: max(CGFloat(min(blue, 255)) / 255, 0),
            alpha: max(CGFloat(min(alpha ?? 255, 255)) / 255, 0)
        )
    }
}
