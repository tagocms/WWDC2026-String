//
//  HStackHeaderView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
//

import SwiftUI

struct HStackHeaderView<T: Hashable & Identifiable & Named>: View {
    // MARK: - Preferences
    @AppStorage("colorKey") private var accentColor = Color.accentColor
    
    // MARK: - State properties
    @Binding var collection: [T]
    @Binding var text: String
    @FocusState private var isFocused
    
    // MARK: - Stored properties
    let titleText: String
    let filteredItems: [T]
    let systemImage: String
    let deleteSystemImage: String
    let onCreate: () -> Void
    let isAllowedToCreate: () -> Bool
    
    // MARK: - Constants
    let standardSpacingAndPadding: CGFloat = 8
    
    
    var body: some View {
        HStack(spacing: standardSpacingAndPadding * 2) {
            Text("\(titleText.capitalized)s")
                .font(.title3.bold())
            HStack(spacing: standardSpacingAndPadding) {
                ForEach(collection) { item in
                    buildButton(for: item)
                }
            }
            
            ZStack(alignment: .searchBarBottom) {
                searchBar
                // TODO: - Melhorar o alignment guide para que o overlay fique literalmente por cima de todos os outros conteúdos dentro da ZStack, mas alinhado abaixo do searchTagsBar
                overlayList
                    .alignmentGuide(VerticalAlignment.searchBarBottom) { dimension in
                        dimension[.top]
                    }
                    .padding(.top, standardSpacingAndPadding)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var searchBar: some View {
        HStack(spacing: standardSpacingAndPadding) {
            Image(systemName: "plus")
            TextField("Add new \(titleText.lowercased())", text: $text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
        .padding(.horizontal, standardSpacingAndPadding)
        .padding(.vertical, standardSpacingAndPadding / 2)
        .background(accentColor.opacity(0.2))
        .foregroundStyle(accentColor)
        .clipShape(.capsule)
        .frame(width: 100, alignment: .leading)
    }
    
    @ViewBuilder
    private var overlayList: some View {
        if isFocused && !text.isEmpty {
            VStack(alignment: .leading, spacing: standardSpacingAndPadding) {
                ForEach(filteredItems) { item in
                    if !collection.contains(item) {
                        Button(item.name, systemImage: systemImage) {
                            withAnimation {
                                collection.append(item)
                                text = ""
                            }
                        }
                        .labelIconToTitleSpacing(standardSpacingAndPadding)
                    }
                }
                if isAllowedToCreate() {
                    Button("Create \(text)", systemImage: "plus") {
                        withAnimation {
                            // TODO: - Lidar com isso e corrigir o bug do overlay das tags - e componentizar isso, para usar nas linkedNotes também.
                            onCreate()
                            text = ""
                        }
                    }
                    .labelIconToTitleSpacing(standardSpacingAndPadding)
                }
            }
            .animation(.default, value: isFocused)
            .transition(.scale)
        }
    }
    
    @ViewBuilder
    private func buildButton(for item: T) -> some View {
        Menu {
            Button("Remove '\(item.name)' from note", systemImage: deleteSystemImage, role: .destructive) {
                withAnimation {
                    collection.removeAll { $0.id == item.id }
                }
            }
        } label: {
            Text(item.name)
                .padding(.horizontal, standardSpacingAndPadding)
                .padding(.vertical, standardSpacingAndPadding / 2)
                .background(accentColor.opacity(0.2))
                .clipShape(.capsule)
        }
    }
}
