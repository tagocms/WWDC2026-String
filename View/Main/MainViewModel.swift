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
        // MARK: - Initialization
        var isLoaded = false
        
        // MARK: - Selection
        var noteToOpen: Note? {
            didSet {
                isBeingCreated = false
            }
        }
        var noteToDelete: Note? {
            didSet {
                isBeingCreated = false
            }
        }
        var isBeingCreated: Bool = false
        var slipboxToOpen: Slipbox? {
            didSet {
                isBeingCreated = false
            }
        }
        var slipboxToDelete: Slipbox? {
            didSet {
                isBeingCreated = false
            }
        }
        
        // MARK: - Filters
        var filterTags: [Tag] = []
        var filterSlipbox: Slipbox? = nil
    }
    var controlModels = ControlModels()
    // MARK: - View state
    var navigationSplitViewVisibility = NavigationSplitViewVisibility.detailOnly
    var sidebarSelection: SidebarSelection? {
        get {
            guard let filterSlipbox = controlModels.filterSlipbox else { return .root }
            return .slipbox(filterSlipbox)
        }
        set {
            switch newValue {
            case .root:
                filterForSlipbox(nil)
            case .slipbox(let slipbox):
                filterForSlipbox(slipbox)
            default:
                filterForSlipbox(nil)
            }
        }
    }
    var isRootSlipboxExpanded: Bool = true
    
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
    
    /// Loads and updates all custom attributes (links and tags) in each note's content body.
    func loadView() {
        for note in notes {
            synchronizeContentBody(for: note)
        }
        controlModels.isLoaded = true
    }
    
    /// Synchronizes each note's content body with their properties (links and tags)
    private func synchronizeContentBody(for note: Note) {
        for linkedNote in notes {
            Note.synchronizeContentBody(
                linkedNote,
                oldFormattedName: linkedNote.formatName,
                allNotes: [note]
            ) { noteToCheck, alteredItem in
                !noteToCheck.linkedNotes.contains(alteredItem)
            } applyChange: { noteToCheck, itemToApply in
                var updatedLinkedNotes = noteToCheck.linkedNotes
                updatedLinkedNotes.append(itemToApply)
                noteToCheck.setLinkedNotes(updatedLinkedNotes)
            } shouldAlterText: { noteToCheck, alteredItem in
                noteToCheck.linkedNotes.contains(alteredItem)
            }
        }
        for tag in tags {
            Note.synchronizeContentBody(
                tag,
                oldFormattedName: tag.formatName,
                allNotes: [note]
            ) { noteToCheck, alteredItem in
                !noteToCheck.tags.contains(alteredItem)
            } applyChange: { noteToCheck, itemToApply in
                var updatedTags = noteToCheck.tags
                updatedTags.append(itemToApply)
                noteToCheck.setTags(updatedTags)
            } shouldAlterText: { noteToCheck, alteredItem in
                noteToCheck.tags.contains(alteredItem)
            }
        }
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
            let welcomeSlipbox = Slipbox(title: "00 - Welcome")
            let fleetingSlipbox = Slipbox(title: "01 - Fleeting")
            let referenceSlipbox = Slipbox(title: "02 - Reference")
            let permanentSlipbox = Slipbox(title: "03 - Permanent")
            modelContext.insert(welcomeSlipbox)
            modelContext.insert(fleetingSlipbox)
            modelContext.insert(referenceSlipbox)
            modelContext.insert(permanentSlipbox)
            
            let tutorialTag = Tag(name: "tutorial")
            let zettelkastenTag = Tag(name: "zettelkasten")
            let personTag = Tag(name: "person")
            let ideaTag = Tag(name: "idea")
            let astrologyTag = Tag(name: "astrology")
            
            let welcomeNote = Note(
                tags: [tutorialTag],
                slipbox: welcomeSlipbox,
                title: "Welcome! Start here",
                contentBody: AttributedString(
                """
                Hello, welcome to ????, a note-taking app designed to make studies easier by helping to link connected information, categorize them by tags and/or folders (named slipboxes here!) and customize their content with rich text-editing capabilities, such as custom fonts, bold text and so much more!
                
                To get started, tap here: /Next Note/
                """
                ),
                position: Position(x: 0, y: 0)
            )
            
            let nextNote = Note(
                tags: [],
                slipbox: welcomeSlipbox,
                title: "Next Note",
                contentBody: AttributedString(
                    """
                    What you've just tapped on is a link between two notes. 
                    You can create links by typing an existing note name between slashes ('/NoteName/'), such as /Next Note/ or /Welcome! Start here/. Use links to connect related information and build your own inter-connected knowledgebase about any topic that interests you.
                    You can also create tags using similar syntax, but instead of slashes, you use only one hashtag at the beggining of the tag's name (#tag_name). Use tags to filter and categorize content more easily.
                    
                    Before your next step, experiment with these fundamentals: complete the link and tag below - for 'Final Tutorial Note' and 'tutorial', respectively.
                    /Final Tutorial N.../
                    #tutor
                    """
                ),
                position: Position(x: 200, y: 0),
            )
            
            let finalTutorialNote = Note(
                tags: [],
                slipbox: welcomeSlipbox,
                title: "Final Tutorial Note",
                contentBody: AttributedString(
                    """
                    Before you begin, it's important to know that you can also create and customize new slipboxes and notes from both inside the note (in the header section) and in the map view. 
                    The map view is the hub for all your notes, and you can configure, customize and organize its positioning as you like. 
                    Speaking of organization, ???? is built primarily for usage alongside the /Zettelkasten Method/, in order to extract the most out of the knowledge you acquire and persist that knowledge for the longest possible time.
                    If you want to know more about this method, tap here: /Zettelkasten Method/
                    """
                ),
                position: Position(x: 400, y: -250),
            )
            
            let zettelkastenTutorialNote = Note(
                tags: [zettelkastenTag],
                slipbox: permanentSlipbox,
                title: "Zettelkasten Method",
                contentBody: AttributedString(
                    """
                    The Zettelkasten Method is a note-taking and knowledge management method popularized by german sociologist /Niklas Luhmann/. It consists of creating atomic notes, which are singular pieces of knowledge extracted from reliable sources, and linking them together in order to build a greater understanding over the studied subjects and expanding the user's learnings - while also creating a larger personal knowledgebase and reference material.
                    
                    The method consists of a list of principles and advocates for the existence of the following kinds of notes:
                    1. Fleeting notes - Fleeting ideas, made to be quickly remembered and discarded.
                    2. Literature notes - Summaries of books, courses, classes, videos etc., written using the one's own words.
                    3. Permanent notes - Atomic notes that consist of a single idea or concept, derived from the previous two types of notes. They should also be written using one's own words.
                    4. Project notes - Notes that may or may not be temporary, but which are linked to projects the user is undertaking or tasks that need to be remembered.
                    
                    ????? can be used for all kinds of notes, but the examples we built are only of the first 3 types. 
                    To see these notes in action, tap one of the following links:
                    1. /Fleeting Note Example/
                    2. /Literature Note Example/
                    3. /Permanent Note Example/
                    """
                ),
                position: Position(x: 400, y: -500),
            )
            let luhmannNote = Note(
                tags: [personTag],
                slipbox: permanentSlipbox,
                title: "Niklas Luhmann",
                contentBody: AttributedString(
                    """
                    Niklas Luhmann was a german sociologist and creator of the /Zettelkasten Method/. He is one of the most prolific authors of all time, publishing over 14.000 pages over the course of his career.
                    """
                ),
                position: Position(x: 400, y: -750),
            )
            
            let fleetingNote = Note(
                tags: [ideaTag, astrologyTag],
                slipbox: fleetingSlipbox,
                title: "Fleeting Note Example",
                contentBody: AttributedString(
                    """
                    I think the sky is blue because of the reflection of the sun's rays over the surface of the ocean. I wonder if that's true.
                    """
                ),
                position: Position(x: 600, y: -750),
            )
            
            let literatureNote = Note(
                tags: [astrologyTag],
                linkedNotes: [fleetingNote],
                slipbox: referenceSlipbox,
                title: "Literature Note Example",
                contentBody: AttributedString(
                    """
                    According to Nasa, the sky is blue because sunlight reaches Earth's atmosphere and is scattered in all directions by all the gases and particles in the air. Blue light is scattered more than the other colors because it travels as shorter, smaller waves. This is why we see a blue sky most of the time.
                    Source: https://spaceplace.nasa.gov/blue-sky/en/
                    """
                ),
                position: Position(x: 800, y: -750),
            )
            
            let permanentNote = Note(
                tags: [astrologyTag],
                linkedNotes: [literatureNote],
                slipbox: permanentSlipbox,
                title: "Permanent Note Example",
                contentBody: AttributedString(
                    """
                    The sky is blue because sunlight reaches Earth's atmosphere and blue light is scattered more than the other colors - due to its shorter waves - creating the effect that the sky is blue.
                    """
                ),
                position: Position(x: 1000, y: -750),
            )
            
            let notesToInsert: [Note] = [
                welcomeNote,
                nextNote,
                finalTutorialNote,
                zettelkastenTutorialNote,
                luhmannNote,
                fleetingNote,
                literatureNote,
                permanentNote
                
            ]
            
            for noteToInsert in notesToInsert {
                modelContext.insert(noteToInsert)
            }
            
            try? modelContext.save()
        }
    }
    
    // MARK: - Intent methods
    /// Updates note position in the model context.
    func updateNotePosition(_ note: Note, to point: CGPoint, in geometry: GeometryProxy, panOffset: CGOffset, zoom: CGFloat, rotation: Angle) {
        note.updatePosition(to: .converted(from: point, in: geometry, panOffset: panOffset, zoom: zoom, rotation: rotation))
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
            controlModels.isBeingCreated = true
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
        controlModels.isBeingCreated = true
        
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
        withAnimation {
            deleteAndSaveToModelContext(model)
            controlModels.slipboxToDelete = nil
            controlModels.noteToDelete = nil
        }
    }
    
    /// Sets a link from one note to the other.
    func setLink(from note: Note, to possibleLink: Note) {
        withAnimation {
            note.addLink(to: possibleLink)
        }
    }
    
    /// Calculates the distance between a note and the user's drag location and, if it coincides with the location of another note, links them together - if not linked, if linked, unlink them.
    func setOrRemoveDraggedLink(from note: Note, to location: CGPoint, in geometry: GeometryProxy, noteSize: CGSize) {
        guard let closestNote = closestNote(from: note, to: location, in: geometry, noteSize: noteSize) else { return }
        
        if note.linkedNotes.contains(closestNote) {
            removeLink(from: note, to: closestNote)
        } else {
            setLink(from: note, to: closestNote)
        }
    }
    
    /// Returns the closest note to the destination location set by the origin note.
    func closestNote(from note: Note, to location: CGPoint, in geometry: GeometryProxy, noteSize: CGSize) -> Note? {
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
        guard let closestNote, closestDistance != nil else { return  nil }
        
        return closestNote
    }
    
    /// Remove a link from one note to another.
    func removeLink(from note: Note, to link: Note) {
        withAnimation {
            note.removeLink(to: link)
        }
    }
    
    /// Treats the user's tap on a tag in the tag filter list.
    func onFilterTagTapped(_ tag: Tag) {
        withAnimation {
            if controlModels.filterTags.contains(tag) {
                controlModels.filterTags.removeAll(where: { $0 == tag })
            } else {
                controlModels.filterTags.append(tag)
            }
        }
    }
    
    /// Filters the notes in the model to the selected slipbox.
    func filterForSlipbox(_ slipbox: Slipbox? = nil) {
        withAnimation {
            controlModels.filterSlipbox = slipbox
            navigationSplitViewVisibility = .detailOnly
        }
    }
    
    // MARK: - Auxiliary methods
    /// Helper function that verifies if a note is inside a slipbox or its child-slipboxes.
    private func isNoteInSlipbox(_ note: Note, slipbox: Slipbox) -> Bool {
        if note.slipbox == slipbox { return true }
        
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
        withAnimation {
            modelContext.insert(item)
            try? modelContext.save()
        }
    }
    
    /// Helper function for deleting a model and saving it to the model context.
    private func deleteAndSaveToModelContext<T: PersistentModel>(_ item: T) {
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
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
