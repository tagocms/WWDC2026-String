import SwiftData
import SwiftUI

struct MainView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MainViewModel!
    @Query(Note.fetchDescriptor) private var notesFromQuery: [Note]
    @Query(Slipbox.fetchDescriptor) private var slipboxesFromQuery: [Slipbox]
    
    // MARK: - Theme and accent color
    @AppStorage("theme") private var theme: Theme = .system
    @AppStorage("colorKey") private var accentColor: Color = Color.accentColor
    
    // MARK: - Settings State
    @State private var isShowingSettings: Bool = false
    @AppStorage("isShowingUIControls") private var isShowingUIControls: Bool = true
    
    // MARK: - Alert
    @State private var isAlertPresented = false
    
    // MARK: - Constants
    struct Constants {
        static let cornerRadius: CGFloat = 12
        static let standardPadding: CGFloat = 8
        
        static let dockBarZIndex: Double = 1000
        static let dockBarDividerHeight: CGFloat = 66
        static let dockBarSpacing: CGFloat = 12
        
        static let noteWidth: CGFloat = 150
        static let aspectRatio: CGFloat = 3/4
        static let cardZIndex: Double = 999
        static let cardSize: CGSize = CGSize(
            width: Constants.noteWidth,
            height: Constants.noteWidth / Constants.aspectRatio
        )
        
        static let linkLineZIndex: Double = 0
    }
    
    // MARK: - View UI State
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    @State private var scaleEffect = 1.0
    @GestureState private var scaleEffectGestureState: CGFloat = 1
    @State private var panDistance: CGOffset = CGOffset.zero
    @GestureState private var panDistanceGestureState: CGOffset = CGOffset.zero
    @State private var rotation: Angle = .zero
    @GestureState private var rotationGestureState: Angle = .zero
    @State private var temporaryLinkPath: Path? = nil
    
    private var totalScaleEffect: CGFloat {
        scaleEffect * scaleEffectGestureState
    }
    private var totalPanDistance: CGOffset {
        panDistance + panDistanceGestureState
    }
    private var totalRotation: Angle {
        rotation + rotationGestureState
    }
    @State private var isInExploringMode: Bool = true
    
    // MARK: - View animations
    @Namespace private var noteNamespace
    @Namespace private var slipboxNamespace
    @Namespace private var defaultNamespace
    
    // MARK: - View Body
    var body: some View {
        Group {
            if let viewModel {
                let bindableViewModel = Bindable(viewModel)
                NavigationSplitView(columnVisibility: bindableViewModel.navigationSplitViewVisibility) {
                    sidebarViewBody(bindableViewModel)
                } detail: {
                    fullViewBody
                }
            } else {
                ProgressView().font(.largeTitle)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = MainViewModel(modelContext)
                viewModel.buildInitialData()
            }
        }
        .onOpenURL { url in
            guard let viewModel else { return }
            viewModel.receiveAndTreatURL(url)
        }
        .preferredColorScheme(theme.colorScheme)
        .tint(accentColor)
    }
}

// MARK: - Slipbox Row View
extension MainView {
    private struct SlipboxRowView: View {
        let slipbox: Slipbox

        var body: some View {
            Group {
                if slipbox.slipboxes.isEmpty {
                    Label(slipbox.name, systemImage: "folder")
                } else {
                    DisclosureGroup {
                        ForEach(slipbox.slipboxes) { nestedSlipbox in
                            SlipboxRowView(slipbox: nestedSlipbox)
                        }
                    } label: {
                        Label(slipbox.name, systemImage: "folder")
                    }
                }
            }
            .tag(SidebarSelection.slipbox(slipbox))
        }
    }
}

// MARK: - View Body components
extension MainView {
    private func sidebarViewBody(_ bindableViewModel: Bindable<MainViewModel>) -> some View {
        List(selection: bindableViewModel.sidebarSelection) {
            DisclosureGroup {
                ForEach(slipboxesFromQuery.filter { $0.parentSlipbox == nil }) { slipbox in
                    listItemView(for: slipbox)
                        .contextMenu {
                            Button("Edit \(slipbox.name)", systemImage: "pencil") {
                                viewModel.controlModels.slipboxToOpen = slipbox
                            }
                            Button("Delete \(slipbox.name)", systemImage: "trash", role: .destructive) {
                                viewModel.controlModels.slipboxToDelete = slipbox
                                isAlertPresented = true
                            }
                        }
                        .matchedTransitionSource(id: slipbox.id, in: slipboxNamespace)
                }
            } label: {
                Label("Root slipbox", systemImage: "folder")
            }
            .tag(SidebarSelection.root)
            .contentShape(Rectangle())
        }
    }
    
    private func listItemView(for slipbox: Slipbox) -> some View {
        SlipboxRowView(slipbox: slipbox)
    }
    
    private var fullViewBody: some View {
        Group {
            if let viewModel {
                let bindableViewModel = Bindable(viewModel)
                GeometryReader { geometry in
                    buildContentBodyWithModifiers(in: geometry)
                }
                .sheet(item: bindableViewModel.controlModels.noteToOpen) { note in
                    NoteView(note)
                        .presentationSizing(.page)
                        .navigationTransition(.zoom(sourceID: note.id, in: noteNamespace))
                        .environment(viewModel)
                }
                .sheet(item: bindableViewModel.controlModels.slipboxToOpen) { slipbox in
                    SlipboxView(slipbox)
                        .navigationTransition(.zoom(sourceID: slipbox.id, in: slipboxNamespace))
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                        .navigationTransition(.zoom(sourceID: "settings", in: defaultNamespace))
                }
                .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
                    viewModel.buildAlertActions()
                } message: {
                    Text(viewModel.alertMessage)
                }
                
            } else {
                ProgressView().font(.largeTitle)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Settings", systemImage: "gear") {
                    isShowingSettings.toggle()
                }
                .matchedTransitionSource(id: "settings", in: defaultNamespace)
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search notes")
        .searchFocused($isSearchFocused)
        .searchSuggestions {
            ForEach(Note.filtered(notesFromQuery, by: searchText).prefix(8)) { item in
                Label(item.name, systemImage: "document")
                    .searchCompletion(item.name)
            }
        }
        .onSubmit(of: .search) {
            guard let first = Note.filtered(notesFromQuery, by: searchText).first else {
                return
            }
            viewModel.controlModels.noteToOpen = first
            searchText = ""
            isSearchFocused = false
        }
    }
    
    private var exploringModeButton: some View {
        Button {
            isInExploringMode.toggle()
        } label: {
            if isInExploringMode {
                IconAndTextView(iconName: "hand.draw", text: "Explore mode")
            } else {
                IconAndTextView(iconName: "link", text: "Link mode")
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var dockBar: some View {
        HStack(alignment: .dockBarLastTextBaseline) {
            fixedDockBarButtons
                .alignmentGuide(VerticalAlignment.dockBarLastTextBaseline) { dimension in
                    dimension[VerticalAlignment.bottom]
                }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.buttonBorder)
        .padding()
        .zIndex(Constants.dockBarZIndex)
    }
    
    @ViewBuilder
    private var fixedDockBarButtons: some View {
        HStack(alignment: .dockBarLastTextBaseline, spacing: Constants.dockBarSpacing) {
            createNewNoteAndSlipboxButtons
            filterMenuButton
        }
    }
    
    @ViewBuilder
    private var createNewNoteAndSlipboxButtons: some View {
        Button {
            viewModel.createNewNote()
        } label: {
            IconAndTextView(iconName: "document.badge.plus", text: "New note")
        }
        
        Button {
            viewModel.createNewSlipbox()
        } label: {
            IconAndTextView(iconName: "folder.badge.plus", text: "New slipbox")
        }
    }
    
    private var filterMenuButton: some View {
        Menu {
            Button("Clear filter", systemImage: "clear", role: .cancel) { viewModel.controlModels.filterTags.removeAll() }
            Menu("Tags", systemImage: "tag") {
                ForEach(viewModel.tags) { tag in
                    Button(
                        tag.name,
                        systemImage: viewModel.controlModels.filterTags.contains(tag) ? "checkmark.circle" : "circle"
                    ) {
                        viewModel.onFilterTagTapped(tag)
                    }
                }
            }
            .menuActionDismissBehavior(.disabled)
        } label: {
            IconAndTextView(iconName: "line.3.horizontal.decrease", text: "Filter")
        }
    }
    
    @ViewBuilder
    private func buildContentBodyWithModifiers(in geometry: GeometryProxy) -> some View {
        Group {
            ZStack(alignment: .topTrailing) {
                buildContentBody(in: geometry)
                exploringModeButton
            }
        }
        .onChange(of: viewModel.controlModels.filterSlipbox) {
            zoomToFit(in: geometry)
        }
        .onChange(of: viewModel.controlModels.filterTags) {
            zoomToFit(in: geometry)
        }
        .onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: .local)
        } action: { _ in
            delayedZoomToFit(in: geometry)
        }
        .gesture(allGestures)
        .onTapGesture(count: 2) {
            zoomToFit(in: geometry)
        }
        .gesture(multitouchGesture)
        .task {
            delayedZoomToFit(in: geometry)
        }
    }
    
    @ViewBuilder
    private func buildContentBody(in geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
            Group {
                buildNotes(in: geometry)
            }
            .scaleEffect(totalScaleEffect, anchor: .center)
            .rotationEffect(totalRotation, anchor: .center)
            .offset(totalPanDistance)
            
            dockBar
            
            if viewModel.filteredNotes(notesFromQuery).isEmpty {
                Button {
                    viewModel.createNewNote()
                } label: {
                    ContentUnavailableView("No notes found", systemImage: "document.badge.plus", description: Text("There are no notes in this slipbox. Create a new one!"))
                        .scaleEffect(1.5)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func buildNotes(in geometry: GeometryProxy) -> some View {
        if let temporaryLinkPath {
            temporaryLinkPath
                .stroke(accentColor)
        }
        ForEach(viewModel.filteredNotes(notesFromQuery)) { note in
            ForEach(note.linkedNotes) { linkedNote in
                buildNotePath(from: note, to: linkedNote, in: geometry)
            }
            .zIndex(Constants.linkLineZIndex)
            buildNoteCard(note, in: geometry)
        }
    }
    
    @ViewBuilder
    private func buildNotePath(from note: Note, to linkedNote: Note, in geometry: GeometryProxy) -> some View {
        if viewModel.filteredNotes(notesFromQuery).contains(linkedNote) {
            Path { path in
                path.move(to: note.position.convertToCGPoint(in: geometry))
                path.addLine(to: linkedNote.position.convertToCGPoint(in: geometry))
            }
            .stroke(accentColor)
        }
    }
    
    @ViewBuilder
    private func buildNoteCardTags(_ note: Note, in geometry: GeometryProxy) -> some View {
        HStack(alignment: .center) {
            Image(systemName: "tag")
            Spacer()
            LazyVGrid(
                columns: [
                    GridItem(
                        .fixed(geometry.size.width * 0.5)
                    )
                ],
                alignment: .leading,
                spacing: 0
            ) {
                ForEach(note.tags) { tag in
                    Text("\(tag.name)")
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.vertical, Constants.standardPadding / 2)
                }
            }
        }
    }
    
    @ViewBuilder
    private func buildContextMenu(for note: Note) -> some View {
        if !isInExploringMode {
            Menu("Link note to", systemImage: "link") {
                ForEach(viewModel.notes) { possibleLink in
                    if viewModel.shouldAllowLink(for: note, possibleLink: possibleLink) {
                        Button(possibleLink.name) {
                            viewModel.setLink(from: note, to: possibleLink)
                        }
                    }
                }
            }
            Menu("Remove link to", systemImage: "nosign") {
                ForEach(note.linkedNotes.sorted()) { link in
                    Button(link.name, role: .cancel) {
                        viewModel.removeLink(from: note, to: link)
                    }
                }
            }
        } else {
            Button("Delete note", systemImage: "trash", role: .destructive) {
                viewModel.controlModels.noteToDelete = note
                isAlertPresented = true
            }
        }
    }
    
    @ViewBuilder
    private func buildNoteCard(_ note: Note, in geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .fill(Color.accentColor)
            .aspectRatio(Constants.aspectRatio, contentMode: .fit)
            .frame(width: Constants.noteWidth)
            .overlay(
                GeometryReader { cardGeometry in
                    VStack(alignment: .leading) {
                        Text("\(note.name)")
                            .font(.title3.bold())
                        if !note.tags.isEmpty {
                            buildNoteCardTags(note, in: geometry)
                        }
                    }
                    .padding(Constants.standardPadding)
                    .foregroundStyle(Color.appBackground)
                }
            )
            .matchedTransitionSource(id: note.id, in: noteNamespace)
            .contextMenu {
                buildContextMenu(for: note)
            }
            .position(note.position.convertToCGPoint(in: geometry))
            .onTapGesture {
                viewModel.controlModels.noteToOpen = note
            }
            .gesture(noteDragGesture(for: note, in: geometry))
            .zIndex(Constants.cardZIndex)
    }
}

// MARK: - UI Size methods
extension MainView {
    private func boundingBox(for note: Note) -> CGRect {
        let bbox = CGRect(
            center: note.position.convertToCGPoint(),
            size: Constants.cardSize
        )
        return bbox
    }
    
    private var boundingBoxForMap: CGRect {
        var boundingBox = CGRect.zero
        for note in viewModel.filteredNotes(notesFromQuery) {
            boundingBox = boundingBox.union(self.boundingBox(for: note))
        }
        return boundingBox
    }
    
    private func delayedZoomToFit(in geometry: GeometryProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            zoomToFit(in: geometry)
        }
    }
    
    private func zoomToFit(in geometry: GeometryProxy) {
        let rotationNormalized = rotation.degrees.isNormal ? rotation.degrees : 0
        withAnimation {
            panDistance = .zero
            rotation = .degrees(Double((Int(rotationNormalized) / 360) * 360))
            
            let bbox = boundingBoxForMap
            let geometryFrame = geometry.frame(in: .local).insetBy(
                dx: Constants.cardSize.width * 0.5 * geometry.size.width / UIScreen.main.bounds.width,
                dy: Constants.cardSize.height * 0.5 * geometry.size.height / UIScreen.main.bounds.height
            )
            
            guard bbox.width > 0,
                  bbox.height > 0,
                  geometryFrame.width > 0,
                  geometryFrame.height > 0 else { return }
            
            let hZoom = geometryFrame.width / bbox.width
            let vZoom = geometryFrame.height / bbox.height
            scaleEffect = min(min(hZoom, vZoom), 2)
            
            panDistance = CGOffset(
                width: -bbox.midX * totalScaleEffect,
                height: -bbox.midY * totalScaleEffect
            )
        }
    }
}


// MARK: - Gestures
extension MainView {
    private var allGestures: some Gesture {
        panGesture
            .simultaneously(with: magnificationGesture)
            .simultaneously(with: rotationGesture)
    }
    
    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .updating($scaleEffectGestureState) { inMotionScale, scaleEffectGestureState, _ in
                withAnimation {
                    scaleEffectGestureState = inMotionScale.magnification
                }
            }
            .onEnded { endingMotionScale in
                scaleEffect *= endingMotionScale.magnification
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($panDistanceGestureState) { inMotionPanDistance, panDistanceGestureState, _ in
                withAnimation {
                    panDistanceGestureState = inMotionPanDistance.translation
                }
            }
            .onEnded { endingPanDistance in
                panDistance += endingPanDistance.translation
            }
    }
    
    private var rotationGesture: some Gesture {
        RotateGesture()
            .updating($rotationGestureState) { inMotionRotationValue, rotationGestureState, _ in
                guard inMotionRotationValue.rotation.degrees.isNormal else { return }
                rotationGestureState = inMotionRotationValue.rotation
            }
            .onEnded { endingRotationValue in
                guard endingRotationValue.rotation.degrees.isNormal else { return }
                rotation += endingRotationValue.rotation
            }
    }
    
    private var multitouchGesture: some UIGestureRecognizerRepresentable {
        MultitouchGestureRecognizer()
            .onEnded { value in
                if value.translation.height < 50 && isSearchFocused {
                    isSearchFocused = false
                } else if value.translation.height >= 50 && !isSearchFocused {
                    isSearchFocused = true
                }
            }
    }
    
    private func noteDragGesture(for note: Note, in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged{ inMotionDragValue in
                withAnimation(.smooth) {
                    if isInExploringMode {
                        viewModel.updateNotePosition(note, to: inMotionDragValue.location, in: geometry, panOffset: .zero, zoom: 1, rotation: .zero)
                    } else {
                        temporaryLinkPath = Path { path in
                            path.move(to: note.position.convertToCGPoint(in: geometry))
                            path.addLine(to: inMotionDragValue.location)
                        }
                    }
                }
            }
            .onEnded { endingDragValue in
                withAnimation(.smooth) {
                    if isInExploringMode {
                        viewModel.updateNotePosition(note, to: endingDragValue.location, in: geometry, panOffset: .zero, zoom: 1, rotation: .zero)
                    } else {
                        viewModel.setDraggedLink(from: note, to: endingDragValue.location, in: geometry, noteSize: Constants.cardSize)
                    }
                }
                temporaryLinkPath = nil
            }
    }
}
