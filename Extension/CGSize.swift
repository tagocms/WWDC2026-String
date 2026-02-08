//
//  CGSize.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 07/02/26.
//

import SwiftUI

extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func +=(lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs + rhs
    }
    
    static func *(lhs: CGSize, rhs: Angle) -> CGSize {
        let radians: Double = rhs.radians
        let x = lhs.width
        let y = -lhs.height
        let cosR = cos(radians)
        let sinR = sin(radians)
        
        let newOffset = CGSize(
            width: x * cosR - y * sinR,
            height: -x * sinR - y * cosR
        )
        return newOffset
    }
}
