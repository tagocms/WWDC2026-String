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
    private var modelContext: ModelContext
    private(set) var notes: [Note] = []
    private(set) var slipboxes: [Slipbox] = []
    
    init(_ modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadAll()
    }
    
    private func reloadAll() {
        loadNotes()
        loadSlipboxes()
    }
    
    private func loadNotes(sortBy sortDescriptors: [SortDescriptor<Note>] = []) {
        do {
            let fetchDescriptor = FetchDescriptor<Note>(sortBy: sortDescriptors)
            self.notes = try modelContext.fetch(fetchDescriptor)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func loadSlipboxes(sortBy sortDescriptors: [SortDescriptor<Slipbox>] = []) {
        do {
            let fetchDescriptor = FetchDescriptor<Slipbox>(sortBy: sortDescriptors)
            self.slipboxes = try modelContext.fetch(fetchDescriptor)
        } catch {
            print(error.localizedDescription)
        }
    }
}
