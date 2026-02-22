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
                
                
                
                HStack(spacing: 16) {
                    Text("Tags")
                        .font(.title3.bold())
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedNoteTags) { tag in
                            buildTagButton(for: tag)
                        }
                    }
                    
                    ZStack(alignment: .searchBarBottom) {
                        buildSearchTagsBar(with: bindableViewModel)
                        // TODO: - Melhorar o alignment guide para que o overlay fique literalmente por cima de todos os outros conteúdos dentro da ZStack, mas alinhado abaixo do searchTagsBar
                        overlayList(with: bindableViewModel)
                            .alignmentGuide(VerticalAlignment.searchBarBottom) { dimension in
                                dimension[.top]
                            }
                            .padding(.top, 8)
                    }
                }
                .buttonStyle(.plain)
            }
            
            Section("Note Content") {
                TextEditor(text: bindableViewModel.selectedNoteContentBody)
                    .attributedTextFormattingDefinition(NoteFormattingDefinition())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.leading)
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
    
    private func buildSearchTagsBar(with bindableViewModel: Bindable<NoteViewModel>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
            TextField("Add tag", text: bindableViewModel.newTagName)
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
    private func overlayList(with bindableViewModel: Bindable<NoteViewModel>) -> some View {
        if focusState == .tags && !viewModel.newTagName.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.filteredTags) { tag in
                    if !viewModel.selectedNoteTags.contains(tag) {
                        Button(tag.name, systemImage: "tag") {
                            withAnimation {
                                viewModel.addTagToNote(tag)
                            }
                        }
                        .labelIconToTitleSpacing(8)
                    }
                }
                if viewModel.isNewTagNameValid() {
                    Button("Create \(viewModel.newTagName)", systemImage: "plus") {
                        withAnimation {
                            // TODO: - Lidar com isso e corrigir o bug do overlay das tags - e componentizar isso, para usar nas linkedNotes também.
                            viewModel.createNewTagAndAddToSelectedNote()
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
                    viewModel.selectedNoteTags.removeAll { $0.id == tag.id }
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
