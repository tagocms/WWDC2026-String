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
@MainActor
class MainViewModel {
    // MARK: - Properties
    private(set) var modelContext: ModelContext
    
    // MARK: - ControlModels
    struct ControlModels {
        // MARK: - Selection
        var noteToOpen: Note?
        var noteToDelete: Note?
        
        var slipboxToOpen: Slipbox?
        var slipboxToDelete: Slipbox?
        
        // MARK: - Filters
        var filterTags: [Tag] = []
        var filterSlipbox: Slipbox? = nil
    }
    var controlModels = ControlModels()
    
    // MARK: - Model arrays
    var notes: [Note] {
        return ((try? modelContext.fetch(Note.fetchDescriptor)) ?? [])
    }
    var filteredNotes: [Note] {
        filteredNotes(notes)
    }
    var slipboxes: [Slipbox] {
        let fetchDescriptor = FetchDescriptor<Slipbox>(sortBy: [])
        return ((try? modelContext.fetch(fetchDescriptor)) ?? []).sorted()
    }
    var tags: [Tag] {
        let fetchDescriptor = FetchDescriptor<Tag>(sortBy: [])
        return ((try? modelContext.fetch(fetchDescriptor)) ?? []).sorted()
    }
    
    // MARK: - Alert
    var alertTitle: String {
        if let slipboxToDelete = controlModels.slipboxToDelete {
            return "Delete slipbox \(slipboxToDelete.name)"
        } else if let noteToDelete = controlModels.noteToDelete {
            return "Delete note \(noteToDelete.name)"
        }
        return ""
    }
    var alertMessage: String {
        if let slipboxToDelete = controlModels.slipboxToDelete {
            return "Are you sure you want to delete this slipbox? Every note and folder inside it will also be deleted - there are \(slipboxToDelete.totalNoteCount) notes inside."
        } else if let noteToDelete = controlModels.noteToDelete {
            return "Are you sure you want to delete this note (\(noteToDelete.name))?"
        }
        return ""
    }
    @ViewBuilder @MainActor
    func buildAlertActions(onDelete: (() -> Void)? = nil) -> some View {
        if let slipboxToDelete = controlModels.slipboxToDelete {
            Button("Cancel", role: .cancel) { self.controlModels.slipboxToDelete = nil }
            Button("Delete") {
                self.delete(slipboxToDelete)
                onDelete?()
            }
        } else if let noteToDelete = controlModels.noteToDelete {
            Button("Cancel", role: .cancel) { self.controlModels.noteToDelete = nil }
            Button("Delete") {
                self.delete(noteToDelete)
                onDelete?()
            }
        }
    }
    
    // MARK: - Initializer functions
    init(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - On receive URL callback
    /// Receives and treats incoming URL, directing the user to a note view.
    func receiveAndTreatURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let queryItems = components.queryItems else { return }
        for item in queryItems {
            guard item.name == "data", let stringData = item.value else { continue }
            guard let uuid = UUID(uuidString: stringData) else { return }
            controlModels.noteToOpen = notes.first(where: { $0.id == uuid })
        }
    }
    
    // MARK: - Initial data
    /// Sets the initial data for the models in the app context, if there are no models stored.
    func buildInitialData() {
        if slipboxes.isEmpty, notes.isEmpty, tags.isEmpty {
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
    
    // MARK: - Intent methods
    /// Updates note position in the model context.
    func updateNotePosition(_ note: Note, to point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset, zoom: CGFloat, rotation: Angle) {
        note.updatePosition(to: .converted(from: point, in: geometry, panOffset: panOffset, zoom: zoom, rotation: rotation))
        try? modelContext.save()
    }
    
    /// Creates a new note in the model context and returns it.
    private func createAndReturnNewNote(with name: String? = nil, in slipbox: Slipbox, shouldAutoOpen: Bool = true) -> Note {
        let title: String
        if let name, Note.isNewNameValid(name, allNotes: notes) {
            title = name
        } else {
            title = nameWithoutDuplicates(for: notes)
        }
        let note = Note(slipbox: slipbox, title: title)
        createAndSaveToModelContext(note)
        if shouldAutoOpen {
            controlModels.noteToOpen = note
        }
        return note
    }
    
    /// Interface for the view, creates a new note in the selected slipbox or in the first available slipbox.
    func createNewNote(with name: String? = nil, shouldAutoOpen: Bool = true) {
        let _ = createAndReturnNewNote(with: name, shouldAutoOpen: shouldAutoOpen)
    }
    
    /// Interface for the view, creates a new note in the selected slipbox or in the first available slipbox and returns it.
    func createAndReturnNewNote(with name: String?, shouldAutoOpen: Bool = true) -> Note {
        if let slipbox = controlModels.filterSlipbox {
            return createAndReturnNewNote(with: name, in: slipbox, shouldAutoOpen: shouldAutoOpen)
        } else if let slipbox = slipboxes.first {
            return createAndReturnNewNote(with: name, in: slipbox, shouldAutoOpen: shouldAutoOpen)
        } else {
            return createAndReturnNewNote(with: name, in: createAndReturnNewSlipbox(), shouldAutoOpen: shouldAutoOpen)
        }
    }
    
    /// Creates and returns a new slipbox.
    func createAndReturnNewSlipbox() -> Slipbox {
        let title = nameWithoutDuplicates(for: slipboxes)
        let slipbox = Slipbox(title: title)
        createAndSaveToModelContext(slipbox)
        
        controlModels.slipboxToOpen = slipbox
        
        return slipbox
    }
    
    /// Primary interface for creating a new slipbox for the view.
    func createNewSlipbox() {
        let _ = createAndReturnNewSlipbox()
    }
    
    /// Creates and returns a new tag.
    func createAndReturnNewTag(name: String) -> Tag? {
        if Tag.isNameValid(name, allTags: tags) {
            let tag = Tag(name: name)
            createAndSaveToModelContext(tag)
            return tag
        }
        return nil
    }
    
    /// Primary interface for creating a new tag for the view.
    func createNewTag(name: String) {
        let _ = createAndReturnNewTag(name: name)
    }
    
    /// Deletes a model from the model context.
    func delete<T: PersistentModel>(_ model: T?) {
        guard let model else { return }
        deleteAndSaveToModelContext(model)
        controlModels.slipboxToDelete = nil
        controlModels.noteToDelete = nil
    }
    
    /// Sets a link from one note to the other.
    func setLink(from note: Note, to possibleLink: Note) {
        note.addLink(to: possibleLink)
    }
    
    /// Calculates the distance between a note and the user's drag location and, if it coincides with the location of another note, links them together.
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
    
    /// Remove a link from one note to another.
    func removeLink(from note: Note, to link: Note) {
        note.removeLink(to: link)
    }
    
    /// Treats the user's tap on a tag in the tag filter list.
    func onFilterTagTapped(_ tag: Tag) {
        if controlModels.filterTags.contains(tag) {
            controlModels.filterTags.removeAll(where: { $0 === tag })
        } else {
            controlModels.filterTags.append(tag)
        }
    }
    
    // MARK: - Auxiliary methods
    /// Helper function that verifies if a note is inside a slipbox or its child-slipboxes.
    private func isNoteInSlipbox(_ note: Note, slipbox: Slipbox) -> Bool {
        if note.slipbox === slipbox { return true }
        
        for childSlipbox in slipbox.slipboxes {
            if isNoteInSlipbox(note, slipbox: childSlipbox) {
                return true
            }
        }
        
        return false
    }
    
    /// Helper function that verifies whether a note contains any tags available in the model collection.
    private func doesNoteContainAnyTag(_ note: Note, tags: [Tag]) -> Bool {
        for noteTag in note.tags {
            if tags.contains(noteTag) {
                return true
            }
        }
        return false
    }
    
    /// Returns a boolean value that denotes whether a link could be created between two notes.
    func shouldAllowLink(for note: Note, possibleLink: Note) -> Bool {
        note != possibleLink && !note.linkedNotes.contains(possibleLink)
    }
    
    /// Helper function for creating a name without duplicates inside the model's collection.
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
    
    /// Helper function for creating a model and saving it to the model context.
    private func createAndSaveToModelContext<T: PersistentModel>(_ item: T) {
        modelContext.insert(item)
        try? modelContext.save()
    }
    
    /// Helper function for deleting a model and saving it to the model context.
    private func deleteAndSaveToModelContext<T: PersistentModel>(_ item: T) {
        modelContext.delete(item)
        try? modelContext.save()
    }
    
    /// Helper function for returning filtered notes from the modelContext.
    func filteredNotes(_ notes: [Note]) -> [Note] {
        notes.filter { note in
            let filter = (controlModels.filterSlipbox, controlModels.filterTags)
            switch filter {
            case let (.none, tags) where tags.isEmpty:
                return true
            case let (.none, tags):
                return doesNoteContainAnyTag(note, tags: tags)
            case let (slipbox?, tags) where tags.isEmpty:
                return isNoteInSlipbox(note, slipbox: slipbox)
            case let (slipbox?, tags):
                return isNoteInSlipbox(note, slipbox: slipbox) && doesNoteContainAnyTag(note, tags: tags)
            }
        }
    }
}

extension Position {
    /// Converts a CGPoint inside a geometry into a Position value.
    static func converted(from point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset = .zero, zoom: CGFloat = 1, rotation: Angle = .zero) -> Position {
        let center = geometry.frame(in: .local).center
        let rotatedOffset = panOffset * rotation
        return Position(
            x: Int((point.x - center.x - rotatedOffset.width) / zoom),
            y: Int(-(point.y - center.y - rotatedOffset.height) / zoom)
        )
    }
    
    /// Converts a Position inside a geometry into a CGPoint value.
    func convertToCGPoint(in geometry: GeometryProxy? = nil, panOffset: CGOffset = .zero, zoom: CGFloat = 1, rotation: Angle = .zero) -> CGPoint {
        let center = geometry?.frame(in: .local).center ?? .zero
        let rotatedOffset = panOffset * rotation
        return CGPoint(
            x: (CGFloat(x) * zoom) + center.x + rotatedOffset.width,
            y: -(CGFloat(y) * zoom) + center.y + rotatedOffset.height
        )
    }
}
