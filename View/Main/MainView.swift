import SwiftData
import SwiftUI

struct MainView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MainViewModel!
    @Query(Note.fetchDescriptor) private var notesFromQuery: [Note]
    @Query(Slipbox.fetchDescriptor) private var slipboxesFromQuery: [Slipbox]
    
    // MARK: - Theme and accent color
    @AppStorage("theme") private var theme: Theme = .light
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
        static let aspectRatio: CGFloat = 1
        static let cardZIndex: Double = 999
        static let cardSize: CGSize = CGSize(
            width: Constants.noteWidth,
            height: Constants.noteWidth / Constants.aspectRatio
        )
        static let dragScale: CGFloat = 1.3
        
        static let linkLineZIndex: Double = 0
    }
    
    // MARK: - View UI State
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    @State private var draggedNote: Note? = nil
    @State private var dragDestination: Note? = nil
    
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
    
    private var sliderBinding: Binding<Double> {
        Binding(
            get: { totalScaleEffect },
            set: { scaleEffect = $0 }
        )
    }
    
    @State private var isInExploringMode: Bool = true
    @State private var shouldDrawPaths: Bool = false
    private func shouldBeInGrayscale(_ note: Note) -> Bool {
        guard let draggedNote else { return false }
        if !isInExploringMode {
            return note != draggedNote && note != dragDestination ? true : false
        } else {
            return note != draggedNote ? true : false
        }
    }
    private func isOriginLinked(_ note: Note, to destination: Note) -> Bool {
        return note.linkedNotes.contains(destination)
    }
    
    // MARK: - View animations
    @Namespace private var noteNamespace
    @Namespace private var slipboxNamespace
    @Namespace private var defaultNamespace
    
    // MARK: - View Body
    var body: some View {
        Group {
            if let viewModel, viewModel.controlModels.isLoaded {
                let bindableViewModel = Bindable(viewModel)
                NavigationSplitView(
                    columnVisibility: bindableViewModel.navigationSplitViewVisibility
                ) {
                    sidebarViewBody(bindableViewModel)
                } detail: {
                    fullViewBody
                }
            } else {
                ProgressView().font(.largeTitle)
            }
        }
        .transition(.opacity)
        .task {
            if viewModel == nil {
                viewModel = MainViewModel(modelContext)
                viewModel.buildInitialData()
                viewModel.loadView()
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation(.easeInOut(duration: 0.5)) {
                        shouldDrawPaths = true
                    }
                }
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
            DisclosureGroup(isExpanded: bindableViewModel.isRootSlipboxExpanded) {
                ForEach(slipboxesFromQuery.filter { $0.parentSlipbox == nil }) { slipbox in
                    SlipboxRowView(slipbox: slipbox)
                        .contextMenu {
                            Button("Edit \(slipbox.name)", systemImage: "pencil") {
                                viewModel.controlModels.slipboxToOpen = slipbox
                            }
                            Button("Delete \(slipbox.name)", systemImage: "trash", role: .destructive) {
                                viewModel.controlModels.slipboxToDelete = slipbox
                                isAlertPresented = true
                            }
                            .tint(nil)
                        }
                        .matchedTransitionSource(id: slipbox.id, in: slipboxNamespace)
                }
            } label: {
                Label("Root", systemImage: "folder")
            }
            .tag(SidebarSelection.root)
            .contentShape(Rectangle())
        }
        .navigationTitle("Slipboxes")
    }
    
    private var fullViewBody: some View {
        Group {
            if let viewModel {
                let bindableViewModel = Bindable(viewModel)
                GeometryReader { geometry in
                    buildContentBodyWithModifiers(in: geometry)
                }
                .sheet(item: bindableViewModel.controlModels.noteToOpen) { note in
                    NoteView(note, isBeingCreated: viewModel.controlModels.isBeingCreated)
                        .presentationSizing(.page)
                        .navigationTransition(.zoom(sourceID: note.id, in: noteNamespace))
                        .environment(viewModel)
                        .scrollBounceBehavior(.basedOnSize)
                }
                .sheet(item: bindableViewModel.controlModels.slipboxToOpen) { slipbox in
                    SlipboxView(slipbox, isBeingCreated: viewModel.controlModels.isBeingCreated)
                        .navigationTransition(.zoom(sourceID: slipbox.id, in: slipboxNamespace))
                        .scrollBounceBehavior(.basedOnSize)
                }
                .sheet(isPresented: $isShowingSettings) {
                    SettingsView()
                        .navigationTransition(.zoom(sourceID: "settings", in: defaultNamespace))
                        .scrollBounceBehavior(.basedOnSize)
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
                .tint(nil)
                .matchedTransitionSource(id: "settings", in: defaultNamespace)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Group {
                    createNewNoteAndSlipboxButtons
                    filterMenuButton
                    Menu("Controls", systemImage: "ellipsis") {
                        Button("Clear tag filter", systemImage: "tag.slash", role: .cancel) { viewModel.controlModels.filterTags.removeAll() }
                        Button {
                            isInExploringMode.toggle()
                        } label: {
                            if isInExploringMode {
                                Label("In exploring mode", systemImage: "hand.draw")
                            } else {
                                Label("In linking mode", systemImage: "personalhotspot")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .automatic, prompt: "Search notes")
        .searchFocused($isSearchFocused)
        .searchToolbarBehavior(.minimize)
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
    
    @ViewBuilder
    private var createNewNoteAndSlipboxButtons: some View {
        Button {
            viewModel.createNewNote()
        } label: {
            Label("New note", systemImage: "document.badge.plus")
        }
        
        Button {
            viewModel.createNewSlipbox()
        } label: {
            Label("New slipbox", systemImage: "folder.badge.plus")
        }
    }
    
    private var filterMenuButton: some View {
        Menu("Tag Filter", systemImage: "tag") {
            ForEach(viewModel.tags) { tag in
                Button(
                    tag.name,
                    systemImage: viewModel.controlModels.filterTags.contains(tag) ? "checkmark.circle" : "circle"
                ) {
                    withAnimation {
                        viewModel.onFilterTagTapped(tag)
                    }
                }
                .contentTransition(.symbolEffect)
                .menuActionDismissBehavior(.disabled)
            }
        }
        .menuActionDismissBehavior(.disabled)
    }
    
    @ViewBuilder
    private func buildContentBodyWithModifiers(in geometry: GeometryProxy) -> some View {
        Group {
            ZStack(alignment: .topTrailing) {
                buildContentBody(in: geometry)
                controlButtons(in: geometry)
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
            
            if viewModel.filteredNotes(notesFromQuery).isEmpty {
                Button {
                    viewModel.createNewNote()
                } label: {
                    ContentUnavailableView("No notes found", systemImage: "document.badge.plus", description: Text("There are no notes in this slipbox and/or filter. Create a new one!"))
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
                .brightness(0.2)
                .transition(.opacity)
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
        if viewModel.filteredNotes(notesFromQuery).contains(linkedNote) && shouldDrawPaths {
            let points = trimmedPoints(from: note, to: linkedNote, in: geometry)
            ArrowShape(
                startPoint: points.start,
                endPoint: points.end
            )
            .stroke(accentColor)
            .brightness(0.2)
            .grayscale(shouldBeInGrayscale(note) && shouldBeInGrayscale(linkedNote) ? 1 : 0)
            .transition(.opacity)
        }
    }
    
    private func edgePoint(from origin: CGPoint, to destination: CGPoint, cardSize: CGSize) -> CGPoint {
        let dx = origin.x - destination.x
        let dy = origin.y - destination.y
        guard dx != 0 || dy != 0 else { return destination }
        
        let halfW = cardSize.width / 2
        let halfH = cardSize.height / 2
        
        var t = CGFloat.infinity
        if dx != 0 { t = min(t, abs(halfW / dx)) }
        if dy != 0 { t = min(t, abs(halfH / dy)) }
        
        return CGPoint(
            x: destination.x + t * dx,
            y: destination.y + t * dy
        )
    }
    
    private func trimmedPoints(from note: Note, to linkedNote: Note, in geometry: GeometryProxy) -> (start: CGPoint, end: CGPoint) {
        let start = note.position.convertToCGPoint(in: geometry)
        let end = linkedNote.position.convertToCGPoint(in: geometry)
        let startScale: CGFloat = (note == draggedNote || note == dragDestination) ? Constants.dragScale : 1
        let endScale: CGFloat = (linkedNote == draggedNote || linkedNote == dragDestination) ? Constants.dragScale : 1
        
        let startCardSize = CGSize(
            width: Constants.cardSize.width * startScale,
            height: Constants.cardSize.height * startScale
        )
        let endCardSize = CGSize(
            width: Constants.cardSize.width * endScale,
            height: Constants.cardSize.height * endScale
        )
        
        let trimmedStart = edgePoint(from: end, to: start, cardSize: startCardSize)
        let trimmedEnd = edgePoint(from: start, to: end, cardSize: endCardSize)
        
        return (trimmedStart, trimmedEnd)
    }
    
    @ViewBuilder
    private func buildNoteCardTags(_ note: Note, in geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: Constants.standardPadding) {
            ForEach(note.tags.prefix(3)) { tag in
                Label(tag.name, systemImage: "tag")
                    .font(.caption)
                    .lineLimit(1)
                    .labelIconToTitleSpacing(Constants.standardPadding)
            }
        }
        .padding(Constants.standardPadding/2)
    }
    
    @ViewBuilder
    private func buildContextMenu(for note: Note) -> some View {
        if !isInExploringMode {
            Menu("Link note to", systemImage: "personalhotspot") {
                ForEach(viewModel.notes) { possibleLink in
                    if viewModel.shouldAllowLink(for: note, possibleLink: possibleLink) {
                        Button(possibleLink.name) {
                            viewModel.setLink(from: note, to: possibleLink)
                        }
                    }
                }
            }
            Menu("Remove link to", systemImage: "personalhotspot.slash") {
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
            .tint(nil)
        }
    }
    
    @ViewBuilder
    private func buildNoteCard(_ note: Note, in geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .fill(accentColor)
            .aspectRatio(Constants.aspectRatio, contentMode: .fit)
            .frame(width: Constants.noteWidth)
            .overlay(
                cardOverlay(for: note)
            )
            .overlay(alignment: .topTrailing) {
                linkingOverlay(for: note)
            }
            .matchedTransitionSource(id: note.id, in: noteNamespace)
            .shadow(radius: 10)
            .grayscale(shouldBeInGrayscale(note) ? 1 : 0)
            .scaleEffect(note == draggedNote || note == dragDestination ? Constants.dragScale : 1)
            .contextMenu {
                buildContextMenu(for: note)
            }
            .position(note.position.convertToCGPoint(in: geometry))
            .onTapGesture {
                viewModel.controlModels.noteToOpen = note
            }
            .gesture(noteDragGesture(for: note, in: geometry))
            .zIndex(Constants.cardZIndex)
            .transition(.scale)
    }
    
    private func cardOverlay(for note: Note) -> some View {
        GeometryReader { cardGeometry in
            VStack(alignment: .leading) {
                Text("\(note.name)")
                    .font(.title3.bold())
                if !note.tags.isEmpty {
                    buildNoteCardTags(note, in: cardGeometry)
                }
            }
            .padding(Constants.standardPadding)
            .foregroundStyle(Color.appBackground)
        }
    }
    
    @ViewBuilder
    private func linkingOverlay(for note: Note) -> some View {
        if let dragDestination, let draggedNote, note == dragDestination {
            Image(systemName: isOriginLinked(draggedNote, to: dragDestination) ? "personalhotspot.slash" : "personalhotspot")
                .symbolEffect(.variableColor, isActive: true)
                .foregroundStyle(Color.appBackground)
                .padding(Constants.standardPadding / 2)
                .background(isOriginLinked(draggedNote, to: dragDestination) ? Color.red : Color.green)
                .clipShape(.circle)
                .padding(2)
                .background(Color.appBackground)
                .clipShape(.circle)
                .padding(Constants.standardPadding / 2)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func controlButtons(in geometry: GeometryProxy) -> some View {
        if isShowingUIControls {
            Group {
                Slider(value: sliderBinding, in: 0...2) {
                    Label("Zoom", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                } minimumValueLabel: {
                    Label("Min", systemImage: "minus.magnifyingglass")
                } maximumValueLabel: {
                    Label("Max", systemImage: "plus.magnifyingglass")
                }

            }
            .frame(width: geometry.size.width * 0.3)
            .padding(Constants.standardPadding / 2)
            .glassEffect()
            .padding(Constants.standardPadding)
            .transition(.opacity)
        }
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
                        let proposed = inMotionScale.magnification * scaleEffect
                        if proposed > 2 {
                            scaleEffectGestureState = 2 / scaleEffect
                        } else if proposed < 0 {
                            scaleEffectGestureState = 0 / scaleEffect
                        } else {
                            scaleEffectGestureState = inMotionScale.magnification
                        }
                    }
                }
                .onEnded { endingMotionScale in
                    scaleEffect = min(max(scaleEffect * endingMotionScale.magnification, 0), 2)
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
                withAnimation {
                    if draggedNote == nil {
                        draggedNote = note
                    }
                    if !isInExploringMode {
                        if let closestDragDestination = viewModel.closestNote(
                            from: note,
                            to: inMotionDragValue.location,
                            in: geometry,
                            noteSize: Constants.cardSize
                        ) {
                            if closestDragDestination != dragDestination {
                                dragDestination = closestDragDestination
                            }
                        } else {
                            dragDestination = nil
                        }
                    }
                }
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
                        viewModel.setOrRemoveDraggedLink(from: note, to: endingDragValue.location, in: geometry, noteSize: Constants.cardSize)
                    }
                }
                withAnimation {
                    temporaryLinkPath = nil
                    draggedNote = nil
                    dragDestination = nil
                }
            }
    }
}

