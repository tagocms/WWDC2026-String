//
//  MainViewModel.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 06/02/26.
//

import SwiftData
import SwiftUI

@Observable
final class MainViewModel {
    private(set) var modelContext: ModelContext?
    var notes: [Note] {
        let fetchDescriptor = FetchDescriptor<Note>(sortBy: [])
        return (try? modelContext?.fetch(fetchDescriptor)) ?? []
    }
    var slipboxes: [Slipbox] {
        let fetchDescriptor = FetchDescriptor<Slipbox>(sortBy: [])
        return (try? modelContext?.fetch(fetchDescriptor)) ?? []
    }
    
    init(_ modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
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
            print(modelContext.insertedModelsArray)
        }
    }
}
