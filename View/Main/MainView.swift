import SwiftData
import SwiftUI

struct MainView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MainViewModel = MainViewModel()
    
    // MARK: - Theme and accent color
    @AppStorage("theme") private var theme: Theme = .system
    @AppStorage("colorKey") private var accentColor: Color = Color(UIColor.systemBlue)
    
    // MARK: - Settings State
    @State private var isShowingSettings: Bool = false
    @AppStorage("isShowingUIControls") private var isShowingUIControls: Bool = true
    @AppStorage("isUI3D") private var isUI3D: Bool = false
    
    // MARK: - Alert
    @State private var isAlertPresented = false
    
    // MARK: - Constants
    struct Constants {
        static let noteWidth: CGFloat = 100
        static let aspectRatio: CGFloat = 2/3
        static let randomPositions: [CGPoint] = (0...10).map { number in
            CGPoint(x: CGFloat(Int.random(in: 0..<900)), y: CGFloat(Int.random(in: 0..<1200)))
        }
        static let cardSize: CGSize = CGSize(
            width: Constants.noteWidth,
            height: Constants.noteWidth / Constants.aspectRatio
        )
    }
    
    // MARK: - View UI State
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
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            fullViewBody
        }
        .preferredColorScheme(theme.colorScheme)
        .tint(accentColor)
    }
    
    // MARK: - View Body components
    private var fullViewBody: some View {
        GeometryReader { geometry in
            buildContentBodyWithModifiers(in: geometry)
        }
        .sheet(item: $viewModel.selectedNote) { note in
            NoteView(note, viewModel: viewModel)
                .presentationSizing(.page)
        }
        .sheet(item: $viewModel.selectedSlipbox) { slipbox in
            SlipboxView(slipbox, viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
            viewModel.buildAlertActions()
        } message: {
            Text(viewModel.alertMessage)
        }
        .task {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
                viewModel.buildExampleData()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Settings", systemImage: "gear") {
                    isShowingSettings.toggle()
                }
            }
        }
    }
    
    private var exploringModeButton: some View {
        Button {
            viewModel.toggleExploringMode()
        } label: {
            if viewModel.isInExploringMode {
                IconAndTextView(iconName: "hand.draw", text: "Explore mode")
            } else {
                IconAndTextView(iconName: "link", text: "Link mode")
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var dockBar: some View {
        HStack(alignment: .center) {
            slipboxesDockBarButtons
            Divider()
                .padding(.horizontal, 8)
                .frame(height: 44)
            fixedDockBarButtons
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.buttonBorder)
        .padding()
        .zIndex(1000)
    }
    
    @ViewBuilder
    private var slipboxesDockBarButtons: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                Button {
                    viewModel.filterSlipbox = nil
                } label: {
                    IconAndTextView(iconName: "folder", text: "All", isSelected: viewModel.filterSlipbox == nil)
                }
                ForEach(viewModel.slipboxes) { slipbox in
                    buildSlipboxButton(slipbox)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private var fixedDockBarButtons: some View {
        HStack(spacing: 12) {
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
            Button("Clear filter", systemImage: "clear", role: .cancel) { viewModel.filterTags.removeAll() }
            Menu("Tags", systemImage: "tag") {
                ForEach(viewModel.tags) { tag in
                    Button(
                        tag.name,
                        systemImage: viewModel.filterTags.contains(tag) ? "checkmark.circle" : "circle"
                    ) {
                        if viewModel.filterTags.contains(tag) { viewModel.filterTags.removeAll(where: { $0 === tag })
                        } else {
                            viewModel.filterTags.append(tag)
                        }
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
        .onChange(of: viewModel.filterSlipbox) { _, _ in
            zoomToFit(in: geometry)
        }
        .onChange(of: viewModel.filterTags) { _, _ in
            zoomToFit(in: geometry)
        }
        .gesture(allGestures)
        .onTapGesture(count: 2) {
            zoomToFit(in: geometry)
        }
        .gesture(multitouchGesture)
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                zoomToFit(in: geometry)
            }
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
            
            if viewModel.filteredNotes.isEmpty {
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
        ForEach(viewModel.filteredNotes) { note in
            ForEach(note.linkedNotes) { linkedNote in
                buildNotePath(from: note, to: linkedNote, in: geometry)
            }
            .zIndex(0)
            buildNoteCard(note, in: geometry)
        }
    }
    
    @ViewBuilder
    private func buildNotePath(from note: Note, to linkedNote: Note, in geometry: GeometryProxy) -> some View {
        if viewModel.filteredNotes.contains(linkedNote) {
            Path { path in
                path.move(to: note.position.convertToCGPoint(in: geometry))
                path.addLine(to: linkedNote.position.convertToCGPoint(in: geometry))
            }
            .stroke(accentColor)
        }
    }
    
    @ViewBuilder
    private func buildNoteCard(_ note: Note, in geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.gray)
            .aspectRatio(Constants.aspectRatio, contentMode: .fit)
            .frame(width: Constants.noteWidth)
            .overlay(
                Text("\(note.name)")
                    .font(.largeTitle.bold())
            )
            .contextMenu {
                if !viewModel.isInExploringMode {
                    Menu("Link note to", systemImage: "link") {
                        ForEach(viewModel.notes) { possibleLink in
                            if note != possibleLink, !note.linkedNotes.contains(possibleLink) {
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
                        viewModel.noteToDelete = note
                        isAlertPresented = true
                    }
                }
            }
            .position(note.position.convertToCGPoint(in: geometry))
            .onTapGesture {
                viewModel.selectedNote = note
            }
            .gesture(noteDragGesture(for: note, in: geometry))
            .zIndex(999)
    }
    
    @ViewBuilder
    private func buildSlipboxButton(_ slipbox: Slipbox) -> some View {
        Button {
            viewModel.filterSlipbox = slipbox
        } label: {
            IconAndTextView(iconName: "folder", text: slipbox.name, isSelected: viewModel.filterSlipbox === slipbox)
        }
        .contextMenu {
            Button {
                viewModel.selectedSlipbox = slipbox
            } label: {
                Label("Edit \(slipbox.name)", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                viewModel.slipboxToDelete = slipbox
                isAlertPresented = true
            } label: {
                Label("Delete \(slipbox.name)", systemImage: "trash")
            }
        }
    }
    
    // MARK: - UI Size methods
    private func boundingBox(for note: Note) -> CGRect {
        let bbox = CGRect(
            center: note.position.convertToCGPoint(),
            size: Constants.cardSize
        )
        return bbox
    }
    
    private var boundingBoxForMap: CGRect {
        var boundingBox = CGRect.zero
        for note in viewModel.filteredNotes {
            boundingBox = boundingBox.union(self.boundingBox(for: note))
        }
        return boundingBox
    }
    
    private func zoomToFit(in geometry: GeometryProxy) {
        let rotationNormalized = rotation.degrees.isNormal ? rotation.degrees : 0
        withAnimation {
            panDistance = .zero
            rotation = .degrees(Double((Int(rotationNormalized) / 360) * 360))
            
            let bbox = boundingBoxForMap
            let geometryFrame = geometry.frame(in: .local).insetBy(dx: Constants.cardSize.width, dy: Constants.cardSize.height)
            
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
    
    // MARK: - Gestures
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
                viewModel.onMultitouchGesture(value)
            }
    }
    
    private func noteDragGesture(for note: Note, in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged{ inMotionDragValue in
                withAnimation(.smooth) {
                    if viewModel.isInExploringMode {
                        viewModel.updateNotePosition(note, to: inMotionDragValue.location, in: geometry, panOffset: .zero, zoom: 1, rotation: .zero)
                    } else {
                        //
                        temporaryLinkPath = Path { path in
                            path.move(to: note.position.convertToCGPoint(in: geometry))
                            path.addLine(to: inMotionDragValue.location)
                        }
                    }
                }
            }
            .onEnded { endingDragValue in
                withAnimation(.smooth) {
                    if viewModel.isInExploringMode {
                        viewModel.updateNotePosition(note, to: endingDragValue.location, in: geometry, panOffset: .zero, zoom: 1, rotation: .zero)
                    } else {
                        viewModel.setDraggedLink(from: note, to: endingDragValue.location, in: geometry, noteSize: Constants.cardSize)
                    }
                }
                temporaryLinkPath = nil
            }
    }
}
