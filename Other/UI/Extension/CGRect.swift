//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 09/02/26.
//

import SwiftUI

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
    
    init(center: CGPoint, size: CGSize) {
        self.init(origin: CGPoint(x: center.x - size.width/2, y: center.y - size.height/2), size: size)
    }
}
