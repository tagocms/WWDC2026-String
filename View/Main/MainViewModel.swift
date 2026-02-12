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
    private(set) var isInExploringMode: Bool = false
    
    var selectedNote: Note?
    var notes: [Note] {
        let fetchDescriptor = FetchDescriptor<Note>(sortBy: [])
        return ((try? modelContext?.fetch(fetchDescriptor)) ?? []).sorted()
    }
    var slipboxes: [Slipbox] {
        let fetchDescriptor = FetchDescriptor<Slipbox>(sortBy: [])
        return ((try? modelContext?.fetch(fetchDescriptor)) ?? []).sorted()
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
    
    // MARK: - Intent functions
    func setViewState(to viewState: ViewState) {
        self.viewState = viewState
    }
    
    func toggleExploringMode() {
        self.isInExploringMode.toggle()
    }
    
    func onMultitouchGesture(_ value: MultitouchGestureRecognizer.Value, perform action: (() -> Void)? = nil) {
        withAnimation {
            if value.translation.height < -50 && viewState != .slipboxes {
                setViewState(to: .slipboxes)
            } else if value.translation.height > 50 && viewState != .map {
                action?()
                setViewState(to: .map)
            }
        }
    }
    
    func updateNotePosition(_ note: Note, to point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset, zoom: CGFloat, rotation: Angle) {
        note.updatePosition(to: .converted(from: point, in: geometry, panOffset: panOffset, zoom: zoom, rotation: rotation))
        try? modelContext?.save()
    }
    
    func createNewNote(in slipbox: Slipbox) {
        let title = nameWithoutDuplicates(for: notes)
        let note = Note(slipbox: slipbox, title: title)
        createAndSaveToModelContext(note)
        
        // TODO: fetch do swift Data (insert do seu elemento no array)
    }
    
    func delete(_ note: Note) {
        deleteAndSaveToModelContext(note)
    }
    
    func setLink(from note: Note, to possibleLink: Note) {
        note.addLink(to: possibleLink)
    }
    
    func setDraggedLink(from note: Note, to location: CGPoint, noteSize: CGSize) {
        // TODO: - Arrumar
        var closestNote: Note? = nil
        var closestDistance: Float? = nil
        notes.forEach { possibleLink in
            let currentDistance = possibleLink.position.distance(to: note.position)
            if closestDistance ?? 0 > currentDistance || closestDistance == nil {
                closestDistance = currentDistance
                closestNote = note
            }
        }
        guard let closestNote, closestDistance != nil else { return }
        setLink(from: note, to: closestNote)
    }
    
    func removeLink(from note: Note, to link: Note) {
        note.removeLink(to: link)
    }
    
    func createNewSlipbox() {
        let title = nameWithoutDuplicates(for: slipboxes)
        let slipbox = Slipbox(title: title)
        createAndSaveToModelContext(slipbox)
    }
    
    // MARK: - Auxiliary methods
    private func nameWithoutDuplicates<T: Named>(for collection: [T]) -> String {
        var name = "Untitled"
        var number = 0
        collection.forEach { item in
            if name == item.name {
                number += 1
                name = "Untitled " + String((number))
            }
        }
        
        return name
    }
    
    private func createAndSaveToModelContext<T: PersistentModel>(_ item: T) {
        modelContext?.insert(item)
        try? modelContext?.save()
    }
    
    private func deleteAndSaveToModelContext<T: PersistentModel>(_ item: T) {
        modelContext?.delete(item)
        try? modelContext?.save()
    }
}

extension Position {
    static func converted(from point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset, zoom: CGFloat, rotation: Angle) -> Position {
        let center = geometry.frame(in: .local).center
        let rotatedOffset = panOffset * rotation
        return Position(
            x: Int((point.x - center.x - rotatedOffset.width) / zoom),
            y: Int(-(point.y - center.y - rotatedOffset.height) / zoom)
        )
    }
    
    func convertToCGPoint(in geometry: GeometryProxy? = nil, panOffset: CGOffset = .zero, zoom: CGFloat = 1, rotation: Angle = .zero) -> CGPoint {
        let center = geometry?.frame(in: .local).center ?? .zero
        let rotatedOffset = panOffset * rotation
        return CGPoint(
            x: (CGFloat(x) * zoom) + center.x + rotatedOffset.width,
            y: -(CGFloat(y) * zoom) + center.y + rotatedOffset.height
        )
    }
}
