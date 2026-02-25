//
//  HStackHeaderView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
//

import SwiftUI

struct HStackHeaderView<T: Hashable & Identifiable & Named & Comparable>: View {
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
    let isTag: Bool
    let onPrimaryAction: ((T) -> Void)?
    let onCreate: () -> Void
    let isAllowedToCreate: () -> Bool
    
    // MARK: - Constants
    let standardSpacingAndPadding: CGFloat = 8
    
    var body: some View {
        HStack(spacing: standardSpacingAndPadding * 2) {
            Text("\(titleText.capitalized)s")
                .font(.title3.bold())
            ScrollView(.horizontal) {
                HStack(spacing: standardSpacingAndPadding) {
                    ForEach(collection) { item in
                        buildButton(for: item)
                    }
                }
            }
            .containerRelativeFrame(.horizontal) { value, axis in
                value * 0.4
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            
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
    
    // MARK: - Initializer
    init(
        collection: Binding<[T]>,
        text: Binding<String>,
        titleText: String,
        filteredItems: [T],
        systemImage: String,
        deleteSystemImage: String,
        isTag: Bool = true,
        onPrimaryAction: ((T) -> Void)? = nil,
        onCreate: @escaping () -> Void,
        isAllowedToCreate: @escaping () -> Bool
    ) {
        self._collection = collection
        self._text = text
        self.titleText = titleText
        self.filteredItems = filteredItems
        self.systemImage = systemImage
        self.deleteSystemImage = deleteSystemImage
        self.isTag = isTag
        self.onPrimaryAction = onPrimaryAction
        self.onCreate = onCreate
        self.isAllowedToCreate = isAllowedToCreate
    }
    
    // MARK: - View components
    private var searchBar: some View {
        HStack(spacing: standardSpacingAndPadding) {
            Image(systemName: "plus")
            TextField("Add new \(titleText.lowercased())", text: $text)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.done)
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
            if !isTag {
                Button("Go to '\(item.name)'", systemImage: systemImage) {
                    onPrimaryAction?(item)
                }
            }
            Button("Remove '\(item.name)' from note", systemImage: deleteSystemImage, role: .destructive) {
                withAnimation {
                    collection.removeAll { $0.id == item.id }
                }
            }
        } label: {
            if isTag {
                Text(item.name)
                    .padding(.horizontal, standardSpacingAndPadding)
                    .padding(.vertical, standardSpacingAndPadding / 2)
                    .background(accentColor.opacity(0.2))
                    .clipShape(.capsule)
            } else {
                Text(item.name)
                    .padding(.horizontal, standardSpacingAndPadding)
                    .padding(.vertical, standardSpacingAndPadding / 2)
                    .foregroundStyle(accentColor)
            }
        }
    }
}
