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
    @State private var isShowingOverlay: Bool = false
    @State private var shouldLetFocusChange: Bool = true
    
    // MARK: - Stored properties
    let titleText: String
    let filteredItems: [T]
    let systemImage: String
    let deleteSystemImage: String
    let isTag: Bool
    let onPrimaryAction: ((T) -> Void)?
    let onCreate: () -> Void
    let isAllowedToCreate: () -> Bool
    let onDelete: ((T) -> Void)?
    
    // MARK: - Constants
    let standardSpacingAndPadding: CGFloat = 8
    
    // MARK: - Helper properties
    private var itemsInSearch: [T] {
        filteredItems.filter({ !collection.contains($0) })
    }
    
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
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            
            Spacer()
            
            searchBar
                .popover(isPresented: $isShowingOverlay) {
                    overlayList
                        .interactiveDismissDisabled()
                }
        }
        .buttonStyle(.plain)
        .onChange(of: isShowingOverlay) { _, newValue in
            if !newValue {
                shouldLetFocusChange = false
            }
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if !shouldLetFocusChange {
                isFocused = oldValue
            } else {
                if isShowingOverlay != isFocused {
                    isShowingOverlay = isFocused
                }
            }
            shouldLetFocusChange = true
        }
        .onSubmit(of: .text) {
            if isAllowedToCreate() {
                onCreate()
            } else {
                guard let filteredItem = filteredItems.first, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return
                }
                withAnimation {
                    collection.append(filteredItem)
                    text = ""
                }
            }
        }
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
        isAllowedToCreate: @escaping () -> Bool,
        onDelete: ((T) -> Void)? = nil
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
        self.onDelete = onDelete
    }
    
    // MARK: - View components
    private var searchBar: some View {
        HStack(spacing: standardSpacingAndPadding) {
            Image(systemName: "plus")
            TextField(text: $text) {
                Text("Add new \(titleText.lowercased())")
                    .foregroundStyle(accentColor.opacity(0.5))
            }
            .lineLimit(1)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)
            .submitLabel(.done)
            .frame(maxWidth: 100)
        }
        .padding(.horizontal, standardSpacingAndPadding)
        .padding(.vertical, standardSpacingAndPadding / 2)
        .background(accentColor.opacity(0.2))
        .foregroundStyle(accentColor)
        .clipShape(.capsule)
        .frame(minWidth: 100, alignment: .leading)
    }
    
    @ViewBuilder
    private var overlayList: some View {
        VStack(alignment: .leading, spacing: standardSpacingAndPadding) {
            ForEach(itemsInSearch.prefix(3)) { item in
                if !collection.contains(item) {
                    Button(item.name, systemImage: systemImage) {
                        withAnimation {
                            collection.append(item)
                            text = ""
                        }
                    }
                    .labelIconToTitleSpacing(standardSpacingAndPadding)
                    .padding(.top, standardSpacingAndPadding/2)
                }
            }
            Group {
                if isAllowedToCreate() {
                    Button("Create \(text)", systemImage: "plus") {
                        withAnimation {
                            onCreate()
                            text = ""
                        }
                    }
                    .labelIconToTitleSpacing(standardSpacingAndPadding)
                    .padding(.top, standardSpacingAndPadding/2)
                } else if itemsInSearch.isEmpty && !text.isEmpty {
                    Label("Can't create \(text)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if itemsInSearch.isEmpty {
                    Label("No items", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            .labelIconToTitleSpacing(standardSpacingAndPadding)
            .padding(.top, standardSpacingAndPadding/2)
        }
        .padding(standardSpacingAndPadding)
        .lineLimit(1)
        .animation(.default, value: isFocused)
        .transition(.scale)
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
                    onDelete?(item)
                }
            }
            .tint(nil)
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
