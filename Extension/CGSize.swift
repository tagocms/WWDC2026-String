//
//  CGSize.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 07/02/26.
//

import SwiftUI

typealias CGOffset = CGSize

extension CGOffset {
    static func +(lhs: CGOffset, rhs: CGOffset) -> CGOffset {
        CGOffset(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    static func +=(lhs: inout CGOffset, rhs: CGOffset) {
        lhs = lhs + rhs
    }
    
    static func *(lhs: CGOffset, rhs: Angle) -> CGOffset {
        let radians: Double = rhs.radians
        let x = lhs.width
        let y = -lhs.height
        let cosR = cos(radians)
        let sinR = sin(radians)
        
        let newOffset = CGOffset(
            width: x * cosR - y * sinR,
            height: -x * sinR - y * cosR
        )
        return newOffset
    }
}
