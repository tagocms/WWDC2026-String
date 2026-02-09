//
//  MainViewModel.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import SwiftData
import SwiftUI

typealias Position = Note.Position

@Observable
final class MainViewModel {
    enum ViewState {
        case map, slipboxes
    }
    
    // MARK: - Properties
    private(set) var modelContext: ModelContext?
    private(set) var viewState: ViewState
    
    var selectedNote: Note?
    var notes: [Note] {
        let fetchDescriptor = FetchDescriptor<Note>(sortBy: [])
        return (try? modelContext?.fetch(fetchDescriptor)) ?? []
    }
    var slipboxes: [Slipbox] {
        let fetchDescriptor = FetchDescriptor<Slipbox>(sortBy: [])
        return (try? modelContext?.fetch(fetchDescriptor)) ?? []
    }
    
    // MARK: - Initializer functions
    init(_ modelContext: ModelContext? = nil, viewState: ViewState = .map) {
        self.modelContext = modelContext
        self.viewState = viewState
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Mock data
    func buildExampleData() {
        if slipboxes.isEmpty, notes.isEmpty, let modelContext {
            let slipbox = Slipbox(title: "General")
            modelContext.insert(slipbox)
            let firstNote = Note(slipbox: slipbox, title: "Nota 1")
            let secondNote = Note(linkedNotes: [firstNote], slipbox: slipbox, title: "Nota 2")
            let thirdNote = Note(linkedNotes: [firstNote, secondNote], slipbox: slipbox, title: "Nota 3")
            let fourthNote = Note(slipbox: slipbox, title: "Nota 4")
            let fifthNote = Note(linkedNotes: [fourthNote, thirdNote], slipbox: slipbox, title: "Nota 5")
            modelContext.insert(firstNote)
            modelContext.insert(secondNote)
            modelContext.insert(thirdNote)
            modelContext.insert(fourthNote)
            modelContext.insert(fifthNote)
            try? modelContext.save()
        }
    }
    
    // MARK: - Handle big changes in View State
    func setViewState(to viewState: ViewState) {
        self.viewState = viewState
    }
    
    func onMultitouchGesture(_ value: MultitouchGestureRecognizer.Value, perform action: () -> Void) {
        withAnimation {
            if value.translation.height < -50 && viewState != .slipboxes {
                setViewState(to: .slipboxes)
            } else if value.translation.height > 50 && viewState != .map {
                action()
                setViewState(to: .map)
            }
        }
    }
}

extension Position {
    func convertFromCGPoint(_ point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset, zoom: CGFloat, rotation: Angle) -> Position {
        let center = geometry.frame(in: .local).center
        let rotatedOffset = panOffset * rotation
        return Position(
            x: Int((point.x - center.x - rotatedOffset.width) / zoom),
            y: Int(-(point.y - center.y - rotatedOffset.height) / zoom)
        )
    }
    
    func convertToCGPoint(in geometry: GeometryProxy, panOffset: CGOffset, zoom: CGFloat, rotation: Angle) -> CGPoint {
        let center = geometry.frame(in: .local).center
        let rotatedOffset = panOffset * rotation
        return CGPoint(x: (CGFloat(x) * zoom) + center.x + rotatedOffset.width, y: -(CGFloat(y) * zoom) + center.y + rotatedOffset.height)
    }
}
