import SwiftData
import SwiftUI

struct MainView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MainViewModel = MainViewModel()
    
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
    
    // MARK: - Constants
    struct Constants {
        static let noteWidth: CGFloat = 100
        static let aspectRatio: CGFloat = 2/3
        static let randomPositions: [CGPoint] = (0...10).map { number in
            CGPoint(x: CGFloat(Int.random(in: 0..<900)), y: CGFloat(Int.random(in: 0..<1200)))
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
                    panDistanceGestureState = inMotionPanDistance.translation * rotation
                }
            }
            .onEnded { endingPanDistance in
                panDistance += endingPanDistance.translation * rotation
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
                    viewModel.updateNotePosition(note, from: inMotionDragValue.location, in: geometry, panOffset: totalPanDistance, zoom: totalScaleEffect, rotation: totalRotation)
                }
            }
            .onEnded { endingDragValue in
                withAnimation {
                    viewModel.updateNotePosition(note, from: endingDragValue.location, in: geometry, panOffset: totalPanDistance, zoom: totalScaleEffect, rotation: totalRotation)
                }
            }
    }
    
    // MARK: - View Body
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch viewModel.viewState {
                case .map:
                    ZStack {
                        Color.white
                        Group {
                            buildNotes(in: geometry)
                            buildLines(in: geometry)
                        }
                        .scaleEffect(totalScaleEffect)
                        .offset(totalPanDistance)
                        .rotationEffect(totalRotation)
                    }
                case .slipboxes:
                    Text("SLIPBOXES")
                        .font(Font.largeTitle.bold())
                }
            }
            .gesture(allGestures)
            .onTapGesture(count: 2) {
                zoomToFit(in: geometry)
            }
            .gesture(multitouchGesture)
            .task {
                if viewModel.modelContext == nil {
                    viewModel.setModelContext(modelContext)
                    viewModel.buildExampleData()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    zoomToFit(in: geometry)
                }
            }
        }
        .background(Color.red)
        .sheet(item: $viewModel.selectedNote) { note in
            NoteView(note: note)
        }
        
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
                .position(note.position.convertToCGPoint(in: geometry, panOffset: totalPanDistance, zoom: totalScaleEffect, rotation: totalRotation))
//                .offset(isBeingDragged(note) ? noteDragOffsetGestureState : .zero)
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
                    path.move(to: note.position.convertToCGPoint(in: geometry, panOffset: totalPanDistance, zoom: totalScaleEffect, rotation: totalRotation))
                    path.addLine(to: linkedNote.position.convertToCGPoint(in: geometry, panOffset: totalPanDistance, zoom: totalScaleEffect, rotation: totalRotation))
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
            if bbox.size.width > 0, bbox.size.height > 0,
               geometry.size.width > 0, geometry.size.height > 0 {
                let hZoom = geometry.size.width / bbox.size.width
                let vZoom = geometry.size.height / bbox.size.height
                print(hZoom)
                print(vZoom)
                scaleEffect = min(hZoom, vZoom)
            }
            
        }
    }
    
    // MARK: - UI Size methods
    private func boundingBox(for note: Note) -> CGRect {
        let bbox = CGRect(
            center: note.position.convertToCGPoint(panOffset: totalPanDistance, zoom: 1, rotation: totalRotation),
            size: CGSize(
                width: Constants.noteWidth,
                height: Constants.noteWidth / Constants.aspectRatio)
        )
        print(bbox)
        return bbox
    }
    
    private var boundingBoxForMap: CGRect {
        var boundingBox = CGRect.zero
        for note in viewModel.notes {
            boundingBox = boundingBox.union(self.boundingBox(for: note))
        }
        print(boundingBox)
        return boundingBox
    }
}
