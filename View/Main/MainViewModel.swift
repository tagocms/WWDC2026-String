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
    
    // MARK: - Selected models
    var selectedNote: Note?
    var noteToDelete: Note?
    
    var selectedSlipbox: Slipbox?
    var slipboxToDelete: Slipbox?
    
    // MARK: - Model arrays
    var notes: [Note] {
        let fetchDescriptor = FetchDescriptor<Note>(sortBy: [])
        return ((try? modelContext?.fetch(fetchDescriptor)) ?? []).sorted()
    }
    var slipboxes: [Slipbox] {
        let fetchDescriptor = FetchDescriptor<Slipbox>(sortBy: [])
        return ((try? modelContext?.fetch(fetchDescriptor)) ?? []).sorted()
    }
    var tags: [Tag] {
        let fetchDescriptor = FetchDescriptor<Tag>(sortBy: [])
        return ((try? modelContext?.fetch(fetchDescriptor)) ?? []).sorted()
    }
    
    // MARK: - Alert
    var alertTitle: String {
        if let slipboxToDelete {
            return "Delete slipbox \(slipboxToDelete.name)"
        } else if let noteToDelete {
            return "Delete note \(noteToDelete.name)"
        }
        return ""
    }
    var alertMessage: String {
        if let slipboxToDelete {
            return "Are you sure you want to delete this slipbox? Every note and folder inside it will also be deleted - there are \(slipboxToDelete.totalNoteCount) notes inside."
        } else if let noteToDelete {
            return "Are you sure you want to delete this note (\(noteToDelete.name))?"
        }
        return ""
    }
    @ViewBuilder @MainActor
    func buildAlertActions(onDelete: (() -> Void)? = nil) -> some View {
        if let slipboxToDelete {
            Button("Cancel", role: .cancel) { self.slipboxToDelete = nil }
            Button("Delete") {
                self.delete(slipboxToDelete)
                onDelete?()
            }
        } else if let noteToDelete {
            Button("Cancel", role: .cancel) { self.noteToDelete = nil }
            Button("Delete") {
                self.delete(noteToDelete)
                onDelete?()
            }
        }
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

    // MARK: - Setters
    func setViewState(to viewState: ViewState) {
        self.viewState = viewState
    }
    
    func toggleExploringMode() {
        self.isInExploringMode.toggle()
    }
    
    // MARK: - Intent methods
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
        selectedNote = note
    }
    
    func delete<T: PersistentModel>(_ model: T?) {
        guard let model else { return }
        deleteAndSaveToModelContext(model)
        slipboxToDelete = nil
    }
    
    func setLink(from note: Note, to possibleLink: Note) {
        note.addLink(to: possibleLink)
    }
    
    func setDraggedLink(from note: Note, to location: CGPoint, in geometry: GeometryProxy, noteSize: CGSize) {
        var closestNote: Note? = nil
        var closestDistance: Float? = nil
        for possibleLink in notes {
            guard possibleLink != note else { continue }
            let currentDistance = possibleLink.position.distance(to: .converted(from: location, in: geometry))
            if (closestDistance ?? 0 > currentDistance || closestDistance == nil) && CGFloat(currentDistance) <= noteSize.width / 2 {
                closestDistance = currentDistance
                closestNote = possibleLink
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
        
        selectedSlipbox = slipbox
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
    static func converted(from point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset = .zero, zoom: CGFloat = 1, rotation: Angle = .zero) -> Position {
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
