//
//  SwiftUIView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 08/02/26.
//

import SwiftUI

struct NoteView: View {
    enum NoteViewFocusState {
        case name, tags, linkedNotes, contentBody
    }
    // MARK: - Dismiss
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Accent color
    @AppStorage("colorKey") private var accentColor: Color = Color(UIColor.systemBlue)
    
    // MARK: - Data
    let note: Note
    @Bindable private var viewModel: MainViewModel
    
    // MARK: - Data UI State
    @State private var name: String
    @State private var parentSlipbox: Slipbox
    @State private var tags: [Tag]
    @State private var newTagName: String = ""
    @State private var linkedNotes: [Note]
    @State private var contentBody: String
    
    // MARK: - Auxiliary
    private var filteredTags: [Tag] {
        Note.filtered(viewModel.tags, by: newTagName)
    }
    
    
    // MARK: - UI State
    @State private var isAlertPresented: Bool = false
    @FocusState private var focusState: NoteViewFocusState?
    
    // MARK: - View
    var body: some View {
        Form {
            Section("Header") {
                TextField("Name", text: $name)
                    .font(.title.bold())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusState, equals: .name)
                
                Picker("Parent Slipbox", selection: $parentSlipbox) {
                    ForEach(viewModel.slipboxes.sorted()) { possibleParent in
                        Text(possibleParent.name)
                            .tag(possibleParent)
                    }
                }
                .font(.title3.bold())
                
                HStack(spacing: 16) {
                    Text("Tags")
                        .font(.title3.bold())
                    HStack(spacing: 8) {
                        ForEach(tags) { tag in
                            buildTagButton(for: tag)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "plus")
                        TextField("Add tag", text: $newTagName)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusState, equals: .tags)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.2))
                    .foregroundStyle(accentColor)
                    .clipShape(.capsule)
                    .frame(width: 100, alignment: .leading)
                    .overlay(overlayList)
                }
                .buttonStyle(.plain)
            }
            
            Section("Content") {
                TextEditor(text: $contentBody)
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
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
        .onChange(of: newTagName) { oldValue, newValue in
            if note.isTagValid(newValue, allTags: viewModel.tags) {
                newTagName = newValue
            } else {
                newTagName = oldValue
            }
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
    
    @ViewBuilder
    private var overlayList: some View {
        VStack(alignment: .leading) {
            ForEach(filteredTags) { tag in
                if !tags.contains(tag) {
                    Button(tag.name) {
                        withAnimation {
                            tags.append(tag)
                            newTagName = ""
                        }
                    }
                }
            }
            if note.isTagValid(newTagName, allTags: viewModel.tags) {
                Button("Create \(newTagName)", systemImage: "plus") {
                    withAnimation {
                        // TODO: - Lidar com isso e corrigir o bug do overlay das tags - e componentizar isso, para usar nas linkedNotes também.
                        if note.isTagValid(newTagName, allTags: viewModel.tags) {
                            tags.append(Tag(name: newTagName))
                            newTagName = ""
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func buildTagButton(for tag: Tag) -> some View {
        Menu {
            Button("Remove tag '\(tag.name)' from note", systemImage: "trash", role: .destructive) {
                withAnimation {
                    tags.removeAll { $0.id == tag.id }
                }
            }
        } label: {
            Text(tag.name)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.2))
                .clipShape(.capsule)
        }
    }
    
    // MARK: - Initializer
    init(_ note: Note, viewModel: MainViewModel) {
        self.note = note
        self._name = State(initialValue: note.name)
        self._parentSlipbox = State(initialValue: note.slipbox)
        self._tags = State(initialValue: note.tags)
        self._linkedNotes = State(initialValue: note.linkedNotes)
        self._contentBody = State(initialValue: note.contentBody)
        self._viewModel = Bindable(viewModel)
    }
    
    // MARK: - Auxiliary functions
    private func saveChanges() {
        note.setName(name, allNotes: viewModel.notes)
        note.setParentSlipbox(parentSlipbox)
        note.setTags(tags)
        note.setLinkedNotes(linkedNotes)
        note.setContent(contentBody)
    }
}
