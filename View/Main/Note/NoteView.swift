//
//  SwiftUIView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 08/02/26.
//

import SwiftData
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
    @Bindable var note: Note
    @Bindable private var viewModel: MainViewModel
    
    // MARK: - Data UI State
    @State private var name: String
    @State private var parentSlipbox: Slipbox
    @State private var tags: [Tag]
    @State private var newTagName: String = ""
    @State private var linkedNotes: [Note]
    @State private var contentBody: AttributedString
    
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
                    
                    ZStack(alignment: .searchBarBottom) {
                        searchTagsBar
                        // TODO: - Melhorar o alignment guide para que o overlay fique literalmente por cima de todos os outros conteúdos dentro da ZStack, mas alinhado abaixo do searchTagsBar
                        overlayList
                            .alignmentGuide(VerticalAlignment.searchBarBottom) { dimension in
                                dimension[.top]
                            }
                            .padding(.top, 8)
                    }
                }
                .buttonStyle(.plain)
            }
            
            Section("Note Content") {
                TextEditor(text: $contentBody)
                    .attributedTextFormattingDefinition(NoteFormattingDefinition())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
                    .frame(height: 800)
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
        .onAppear {
            applyChangesToAttributedText()
        }
        .onChange(of: contentBody) {
            applyChangesToAttributedText()
        }
        .onChange(of: newTagName) { oldValue, newValue in
            if Tag.isNameValid(newValue, allTags: viewModel.tags) {
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
    
    private var searchTagsBar: some View {
        HStack(spacing: 8) {
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
    }
    
    @ViewBuilder
    private var overlayList: some View {
        if focusState == .tags && !newTagName.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(filteredTags) { tag in
                    if !tags.contains(tag) {
                        Button(tag.name, systemImage: "tag") {
                            withAnimation {
                                tags.append(tag)
                                newTagName = ""
                            }
                        }
                        .labelIconToTitleSpacing(8)
                    }
                }
                if Tag.isNameValid(newTagName, allTags: viewModel.tags) {
                    Button("Create \(newTagName)", systemImage: "plus") {
                        withAnimation {
                            // TODO: - Lidar com isso e corrigir o bug do overlay das tags - e componentizar isso, para usar nas linkedNotes também.
                            tags.append(viewModel.createAndReturnNewTag(name: newTagName))
                            newTagName = ""
                        }
                    }
                    .labelIconToTitleSpacing(8)
                }
            }
            .animation(.default, value: focusState)
            .transition(.scale)
        }
    }
    
    @ViewBuilder
    private func buildTagButton(for tag: Tag) -> some View {
        Menu {
            Button("Remove tag '\(tag.name)' from note", systemImage: "tag.slash", role: .destructive) {
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
    private func applyChangesToAttributedText() {
        // LinkedNotes
        let notesToLinkTitles: [UUID: AttributedString] = Dictionary(uniqueKeysWithValues: viewModel.notes.map { ($0.id, AttributedString($0.formatName)) })
        var notesToLinkRanges: [UUID: RangeSet<AttributedString.Index>] = [:]
        
        for noteToLink in notesToLinkTitles {
            notesToLinkRanges[noteToLink.key] = RangeSet(contentBody.characters.ranges(of: noteToLink.value.characters))
        }
        
        for rangeSet in notesToLinkRanges {
            guard let noteToLink = viewModel.notes.first(where: { $0.id == rangeSet.key }),
                  !rangeSet.value.isEmpty else {
                continue
            }
            contentBody[rangeSet.value].linkedNote = rangeSet.key
            if !linkedNotes.contains(noteToLink) {
                linkedNotes.append(noteToLink)
            }
        }
        
        // Tags
        let tagTitles: [UUID: AttributedString] = Dictionary(uniqueKeysWithValues: viewModel.tags.map { ($0.id, AttributedString($0.formatName)) })
        var tagRanges: [UUID: RangeSet<AttributedString.Index>] = [:]
        
        for tagTitle in tagTitles {
            tagRanges[tagTitle.key] = RangeSet(contentBody.characters.ranges(of: tagTitle.value.characters))
        }
        
        for rangeSet in tagRanges {
            guard let tag = viewModel.tags.first(where: { $0.id == rangeSet.key }),
                  !rangeSet.value.isEmpty else {
                continue
            }
            contentBody[rangeSet.value].tag = rangeSet.key
            if !tags.contains(tag) {
                tags.append(tag)
            }
        }
    }
    
    private func saveChanges() {
        note.setContent(contentBody)
        note.setName(name, allNotes: viewModel.notes)
        note.setParentSlipbox(parentSlipbox)
        note.setTags(tags)
        note.setLinkedNotes(linkedNotes)
    }
}
