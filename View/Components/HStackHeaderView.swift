////
////  HStackHeaderView.swift
////  CreativeChallenge
////
////  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
////
//
//import SwiftUI
//
//struct HStackHeaderView<T: Hashable & Identifiable & Named>: View {
//    @AppStorage("colorKey") private var accentColor = Color.accentColor
//    @Binding var collection: [T]
//    @Binding var text: String
//    @FocusState var focusState: NoteView.NoteViewFocusState?
//    let filteredItems: [T]
//    let focusStateForView: NoteView.NoteViewFocusState
//    let isTag: Bool
//    let promptText: String
//    let systemImage: String
//    let onCreate: () -> Void
//    let onDelete: () -> Void
//    
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            Text("Tags")
//                .font(.title3.bold())
//            HStack(spacing: 8) {
//                ForEach(collection) { item in
//                    buildButton(for: item)
//                }
//            }
//            
//            ZStack(alignment: .searchBarBottom) {
//                searchBar
//                // TODO: - Melhorar o alignment guide para que o overlay fique literalmente por cima de todos os outros conteúdos dentro da ZStack, mas alinhado abaixo do searchTagsBar
//                overlayList
//                    .alignmentGuide(VerticalAlignment.searchBarBottom) { dimension in
//                        dimension[.top]
//                    }
//                    .padding(.top, 8)
//            }
//        }
//        .buttonStyle(.plain)
//    }
//    
//    private var searchBar: some View {
//        HStack(spacing: 8) {
//            Image(systemName: "plus")
//            TextField(promptText, text: $text)
//                .lineLimit(1)
//                .fixedSize(horizontal: true, vertical: false)
//                .textInputAutocapitalization(.never)
//                .autocorrectionDisabled()
//                .focused($focusState, equals: focusStateForView)
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//        .background(accentColor.opacity(0.2))
//        .foregroundStyle(accentColor)
//        .clipShape(.capsule)
//        .frame(width: 100, alignment: .leading)
//    }
//    
//    @ViewBuilder
//    private var overlayList: some View {
//        if focusState == focusStateForView && !text.isEmpty {
//            VStack(alignment: .leading, spacing: 8) {
//                ForEach(filteredItems) { item in
//                    if !collection.contains(item) {
//                        Button(item.name, systemImage: systemImage) {
//                            withAnimation {
//                                collection.append(item)
//                                text = ""
//                            }
//                        }
//                        .labelIconToTitleSpacing(8)
//                    }
//                }
//                if Tag.isNameValid(text, allTags: collection) {
//                    Button("Create \(text)", systemImage: "plus") {
//                        withAnimation {
//                            // TODO: - Lidar com isso e corrigir o bug do overlay das tags - e componentizar isso, para usar nas linkedNotes também.
//                            onCreate()
//                            text = ""
//                        }
//                    }
//                    .labelIconToTitleSpacing(8)
//                }
//            }
//            .animation(.default, value: focusState)
//            .transition(.scale)
//        }
//    }
//    
//    @ViewBuilder
//    private func buildButton(for item: T) -> some View {
//        Menu {
//            Button("Remove '\(item.name)' from note", systemImage: "tag.slash", role: .destructive) {
//                withAnimation {
//                    collection.removeAll { $0.id == item.id }
//                }
//            }
//        } label: {
//            Text(item.name)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(accentColor.opacity(0.2))
//                .clipShape(.capsule)
//        }
//    }
//}
