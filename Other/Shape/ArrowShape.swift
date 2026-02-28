//
//  SwiftUIView.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 26/02/26.
//

import SwiftUI

struct ArrowShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var arrowHeadLength: CGFloat = 20
    var arrowHeadAngle: CGFloat = .pi / 6
    
    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(startPoint.x, startPoint.y),
                AnimatablePair(endPoint.x, endPoint.y)
            )
        }
        set {
            startPoint = CGPoint(x: newValue.first.first, y: newValue.first.second)
            endPoint = CGPoint(x: newValue.second.first, y: newValue.second.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let lineAngle = atan2(dy, dx)
            
            let leftAngle = lineAngle + .pi - arrowHeadAngle
            let leftPoint = CGPoint(
                x: endPoint.x + arrowHeadLength * cos(leftAngle),
                y: endPoint.y + arrowHeadLength * sin(leftAngle)
            )
            
            let rightAngle = lineAngle + .pi + arrowHeadAngle
            let rightPoint = CGPoint(
                x: endPoint.x + arrowHeadLength * cos(rightAngle),
                y: endPoint.y + arrowHeadLength * sin(rightAngle)
            )
            
            path.move(to: leftPoint)
            path.addLine(to: endPoint)
            path.addLine(to: rightPoint)
        }
    }
}
