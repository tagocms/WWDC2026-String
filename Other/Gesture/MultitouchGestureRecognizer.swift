//
//  MultitouchGestureRecognizer.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 05/02/26.
//

import SwiftUI

@MainActor @preconcurrency
struct MultitouchGestureRecognizer: UIGestureRecognizerRepresentable {
    struct Value: Equatable, Sendable {
        var location: CGPoint
        var startLocation: CGPoint
        var translation: CGSize {
            CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.startLocation == rhs.startLocation && lhs.location == rhs.location
        }
    }
    typealias State = GestureState<Value>
    
    let allowsSimultaneousGestures = false
    let minimumNumberOfTouches: Int
    let maximumNumberOfTouches: Int
    let minimumDistance: CGFloat
    let coordinateSpace: CoordinateSpaceProtocol
    
    var updating: (((Value), inout GestureState<(Value)>) -> Void)?
    var onChanged: ((Value) -> Void)?
    var onEnded: ((Value) -> Void)?
    var gestureState: State?
    
    
    init(
        minimumNumberOfTouches: Int = 2,
        maximumNumberOfTouches: Int = 2,
        minimumDistance: CGFloat = 50,
        coordinateSpace: CoordinateSpaceProtocol = .local) {
        self.minimumNumberOfTouches = minimumNumberOfTouches
        self.maximumNumberOfTouches = maximumNumberOfTouches
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
    }
    
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.maximumNumberOfTouches = maximumNumberOfTouches
        gesture.minimumNumberOfTouches = minimumNumberOfTouches
        gesture.delegate = context.coordinator
        return gesture
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began:
            context.coordinator.dragStart(context.converter.location(in: coordinateSpace))
            break
        case .changed:
            let location = context.converter.location(in: coordinateSpace)
            
            guard context.coordinator.shouldEnableGesture(to: location, minimumDistance: minimumDistance) else { return }
            onChanged?(Value(
                location: location,
                startLocation: context.coordinator.startLocation ?? .zero
            ))
            break
        case .ended:
            let location = context.converter.location(in: coordinateSpace)
            guard context.coordinator.shouldEnableGesture(to: location, minimumDistance: minimumDistance) else { return }
            onEnded?(Value(
                location: location,
                startLocation: context.coordinator.startLocation ?? .zero
            ))
            context.coordinator.dragEnd()
            break
        default:
            break
        }
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> MultitouchGestureCoordinator {
        MultitouchGestureCoordinator(self)
    }
}

extension MultitouchGestureRecognizer {
    func updating(_ gestureState: GestureState<Value>, perform action: @escaping (Value, inout State) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.updating = action
        mutableSelf.gestureState = gestureState
        return mutableSelf
    }
    
    func onChanged(perform action: @escaping (Value) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onChanged = action
        return mutableSelf
    }
    
    func onEnded(perform action: @escaping (Value) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onEnded = action
        return mutableSelf
    }
}

final class MultitouchGestureCoordinator: NSObject, UIGestureRecognizerDelegate {
    let parent: MultitouchGestureRecognizer
    var startLocation: CGPoint?
    private var gestureSucceeded: Bool = false
    
    init(_ parent: MultitouchGestureRecognizer) {
        self.parent = parent
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        parent.allowsSimultaneousGestures
    }
    
    func shouldEnableGesture(to point: CGPoint, minimumDistance: CGFloat) -> Bool {
        guard let startLocation else { return false }
        let distance = abs(hypot(startLocation.x - point.x, startLocation.y - point.y))
        gestureSucceeded = distance > minimumDistance
        return gestureSucceeded
    }
    
    func dragStart(_ location: CGPoint) {
        self.startLocation = location
    }
    
    func dragEnd() {
        self.startLocation = nil
        gestureSucceeded = false
    }
}
