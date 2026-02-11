import SwiftData
import SwiftUI

struct MainView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MainViewModel = MainViewModel()
    
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
    
    private var totalScaleEffect: CGFloat {
        scaleEffect * scaleEffectGestureState
    }
    private var totalPanDistance: CGOffset {
        panDistance + panDistanceGestureState
    }
    private var totalRotation: Angle {
        rotation + rotationGestureState
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
                withAnimation {
                    viewModel.updateNotePosition(note, to: inMotionDragValue.location, in: geometry, panOffset: .zero, zoom: 1, rotation: .zero)
                }
            }
            .onEnded { endingDragValue in
                withAnimation {
                    viewModel.updateNotePosition(note, to: endingDragValue.location, in: geometry, panOffset: .zero, zoom: 1, rotation: .zero)
                }
            }
    }
    
    // MARK: - View Body
    var body: some View {
        GeometryReader { geometry in
            Group {
                ZStack(alignment: .bottom) {
                    // TODO: - Alterar a cor para modo escuro
                    Color.white
                    Group {
                        buildNotes(in: geometry)
                        buildLines(in: geometry)
                    }
                    .scaleEffect(totalScaleEffect, anchor: .center)
                    .rotationEffect(totalRotation, anchor: .center)
                    .offset(totalPanDistance)
                    dockBar
                }
            }
            .gesture(allGestures)
            .onTapGesture(count: 2) {
                zoomToFit(in: geometry)
            }
            .gesture(multitouchGesture)
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    zoomToFit(in: geometry)
                }
            }
        }
        .background(Color.red)
        .sheet(item: $viewModel.selectedNote) { note in
            NoteView(note: note)
        }
        .task {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
                viewModel.buildExampleData()
            }
        }
        
    }
    
    @ViewBuilder
    private var dockBar: some View {
        HStack {
            ForEach(viewModel.slipboxes) { slipbox in
                Button {
                    //
                } label: {
                    Label(slipbox.name, systemImage: "folder")
                }
            }
        }
        .padding()
    }
    
    // MARK: - View UI Methods
    @ViewBuilder
    private func buildNotes(in geometry: GeometryProxy) -> some View {
        ForEach(viewModel.notes) { note in
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray)
                .aspectRatio(Constants.aspectRatio, contentMode: .fit)
                .frame(width: Constants.noteWidth)
                .overlay(
                    Text("\(note.name)")
                        .font(.largeTitle.bold())
                )
                .position(note.position.convertToCGPoint(in: geometry))
                .onTapGesture {
                    viewModel.selectedNote = note
                }
                .gesture(noteDragGesture(for: note, in: geometry))
        }
        .zIndex(1000)
    }
    
    @ViewBuilder
    private func buildLines(in geometry: GeometryProxy) -> some View {
        ForEach(viewModel.notes) { note in
            ForEach(note.linkedNotes) { linkedNote in
                Path { path in
                    path.move(to: note.position.convertToCGPoint(in: geometry))
                    path.addLine(to: linkedNote.position.convertToCGPoint(in: geometry))
                }
                .stroke(.purple)
            }
        }
        .zIndex(0)
    }
    
    private func zoomToFit(in geometry: GeometryProxy) {
        let rotationNormalized = rotation.degrees.isNormal ? rotation.degrees : 0
        withAnimation {
            panDistance = .zero
            rotation = .degrees(Double((Int(rotationNormalized) / 360) * 360))
            
            let bbox = boundingBoxForMap
            let geometryFrame = geometry.frame(in: .local).insetBy(dx: Constants.cardSize.width, dy: Constants.cardSize.height)
            
            print(bbox)
            print(geometryFrame)
            
            guard bbox.width > 0,
                  bbox.height > 0,
                  geometryFrame.width > 0,
                  geometryFrame.height > 0 else { return }
            
            let hZoom = geometryFrame.width / bbox.width
            let vZoom = geometryFrame.height / bbox.height
            scaleEffect = min(min(hZoom, vZoom), 2)
        }
    }
    
    // MARK: - UI Size methods
    private func boundingBox(for note: Note) -> CGRect {
        let bbox = CGRect(
            center: note.position.convertToCGPoint(),
            size: Constants.cardSize
        )
        print()
        print("Bounding box for note \(note.name): \(bbox)")
        print("Real positions for note \(note.name): x - \(note.position.x); y - \(note.position.y)")
        print()
        return bbox
    }
    
    private var boundingBoxForMap: CGRect {
        var boundingBox = CGRect.zero
        for note in viewModel.notes {
            boundingBox = boundingBox.union(self.boundingBox(for: note))
        }
        return boundingBox
    }
}
