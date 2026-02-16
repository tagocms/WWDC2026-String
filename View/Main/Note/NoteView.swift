//
//  SwiftUIView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 08/02/26.
//

import SwiftUI

struct NoteView: View {
    // MARK: - Dismiss
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Data
    let note: Note
    @Bindable private var viewModel: MainViewModel
    
    // MARK: - Data UI State
    @State private var name: String
    @State private var contentBody: String
    @State private var parentSlipbox: Slipbox
    
    // MARK: - UI State
    @State private var isAlertPresented: Bool = false
    
    // MARK: - View
    var body: some View {
        Form {
            Section("Header") {
                TextField("Name", text: $name)
                    .font(.title.bold())
                Picker("Parent Slipbox", selection: $parentSlipbox) {
                    ForEach(viewModel.slipboxes.sorted()) { possibleParent in
                        Text(possibleParent.name)
                            .tag(possibleParent)
                    }
                }
            }
            
            Section("Content") {
                TextEditor(text: $contentBody)
            }
            
            Section {
                Button("Delete note", role: .destructive) {
                    viewModel.noteToDelete = note
                    isAlertPresented = true
                }
            }
        }
        .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
            viewModel.buildAlertActions {
                dismiss()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: name) { oldValue, newValue in
            if note.isNameValid(newValue, allNotes: viewModel.notes) {
                name = newValue
            } else {
                name = oldValue
            }
        }
        .onDisappear(perform: saveChanges)
    }
    
    // MARK: - Initializer
    init(_ note: Note, viewModel: MainViewModel) {
        self.note = note
        self._name = State(initialValue: note.name)
        self._contentBody = State(initialValue: note.contentBody)
        self._parentSlipbox = State(initialValue: note.slipbox)
        self._viewModel = Bindable(viewModel)
    }
    
    // MARK: - Auxiliary functions
    private func saveChanges() {
        note.setName(name, allNotes: viewModel.notes)
        note.setParentSlipbox(parentSlipbox)
        note.setContent(contentBody)
    }
}
