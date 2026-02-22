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
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Accent color
    @AppStorage("colorKey") private var accentColor: Color = Color.accentColor
    
    // MARK: - Data
    @Bindable var note: Note
    @State private var viewModel: NoteViewModel!
    
    // MARK: - UI State
    @State private var isAlertPresented: Bool = false
    @FocusState private var focusState: NoteViewFocusState?
    
    // MARK: - View
    var body: some View {
        Group {
            if let viewModel {
                let bindableViewModel = Bindable(viewModel)
                buildForm(with: bindableViewModel)
                .onAppear {
                    applyChangesToAttributedText()
                }
                .onChange(of: viewModel.selectedNoteContentBody) {
                    applyChangesToAttributedText()
                }
                .onChange(of: viewModel.selectedNoteName) {
                    applyChangesToAttributedText()
                }
                .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
                    viewModel.buildAlertActions {
                        dismiss()
                    }
                } message: {
                    Text(viewModel.alertMessage)
                }
            } else {
                ProgressView().font(.largeTitle)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = NoteViewModel(modelContext, note: note)
            }
        }
    }
    
    // MARK: - View components
    private func buildForm(with bindableViewModel: Bindable<NoteViewModel>) -> some View {
        Form {
            Section("Header") {
                TextField("Name", text: bindableViewModel.selectedNoteName)
                    .font(.title.bold())
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusState, equals: .name)
                
                Picker("Parent Slipbox", selection: bindableViewModel.selectedNoteParentSlipbox) {
                    ForEach(viewModel.slipboxes.sorted()) { possibleParent in
                        Text(possibleParent.name)
                            .tag(possibleParent)
                    }
                }
                .font(.title3.bold())
                
                HStackHeaderView(
                    collection: bindableViewModel.selectedNoteTags,
                    text: bindableViewModel.newTagName,
                    titleText: "tag",
                    filteredItems: viewModel.filteredTags,
                    systemImage: "tag",
                    deleteSystemImage: "tag.slash",
                    onCreate: viewModel.createNewTagAndAddToSelectedNote,
                    isAllowedToCreate: viewModel.isNewTagNameValid
                )
            }
            
            Section("Note Content") {
                TextEditor(text: bindableViewModel.selectedNoteContentBody)
                    .attributedTextFormattingDefinition(NoteFormattingDefinition())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(height: 800)
            }
            
            Section {
                Button("Delete note", role: .destructive) {
                    viewModel.controlModels.noteToDelete = note
                    isAlertPresented = true
                }
            }
        }
    }
    
    // MARK: - Initializer
    init(_ note: Note) {
        self._note = Bindable(note)
    }
    
    // MARK: - Auxiliary functions
    private func applyChangesToAttributedText() {
        // LinkedNotes
        let notesToLinkTitles: [UUID: AttributedString] = Dictionary(uniqueKeysWithValues: viewModel.notes.map { ($0.id, AttributedString($0.formatName)) })
        var notesToLinkRanges: [UUID: RangeSet<AttributedString.Index>] = [:]
        
        for noteToLink in notesToLinkTitles {
            notesToLinkRanges[noteToLink.key] = RangeSet(viewModel.selectedNoteContentBody.characters.ranges(of: noteToLink.value.characters))
        }
        
        for rangeSet in notesToLinkRanges {
            guard let noteToLink = viewModel.notes.first(where: { $0.id == rangeSet.key }),
                  !rangeSet.value.isEmpty else {
                continue
            }
            viewModel.selectedNoteContentBody[rangeSet.value].linkedNote = rangeSet.key
            if !viewModel.selectedNoteLinkedNotes.contains(noteToLink) {
                viewModel.selectedNoteLinkedNotes.append(noteToLink)
            }
        }
        
        // Tags
        let tagTitles: [UUID: AttributedString] = Dictionary(uniqueKeysWithValues: viewModel.tags.map { ($0.id, AttributedString($0.formatName)) })
        var tagRanges: [UUID: RangeSet<AttributedString.Index>] = [:]
        
        for tagTitle in tagTitles {
            tagRanges[tagTitle.key] = RangeSet(viewModel.selectedNoteContentBody.characters.ranges(of: tagTitle.value.characters))
        }
        
        for rangeSet in tagRanges {
            guard let tag = viewModel.tags.first(where: { $0.id == rangeSet.key }),
                  !rangeSet.value.isEmpty else {
                continue
            }
            viewModel.selectedNoteContentBody[rangeSet.value].tag = rangeSet.key
            if !viewModel.selectedNoteTags.contains(tag) {
                viewModel.selectedNoteTags.append(tag)
            }
        }
    }
}
