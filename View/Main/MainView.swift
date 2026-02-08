import SwiftData
import SwiftUI

struct MainView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MainViewModel = MainViewModel()
    
    // MARK: - View UI State
    @State private var scaleEffect = 1.0
    @GestureState private var scaleEffectGestureState: CGFloat = 1
    @State private var panDistance: CGSize = CGSize.zero
    @GestureState private var panDistanceGestureState: CGSize = CGSize.zero
    @State private var rotation: Angle = .zero
    @GestureState private var rotationGestureState: Angle = .zero
    
    let constantPositions: [CGPoint] = (0...10).map { number in
        CGPoint(x: CGFloat(Int.random(in: 0..<900)), y: CGFloat(Int.random(in: 0..<1200)))
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
                viewModel.onMultitouchGesture(value, perform: zoomToFit)
            }
    }
    
    // MARK: - View Body
    var body: some View {
        GeometryReader { geometry in
            switch viewModel.viewState {
            case .map:
                ZStack {
                    Color.white
                    buildRectangles(in: geometry)
                    buildLines(in: geometry)
                }
            case .slipboxes:
                Text("SLIPBOXES")
                    .font(Font.largeTitle.bold())
            }
        }
        .background(Color.red)
        .gesture(allGestures)
        .onTapGesture(count: 2) {
            zoomToFit()
        }
        .gesture(multitouchGesture)
        .task {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
                viewModel.buildExampleData()
            }
        }
    }
    
    // MARK: - View UI Methods
    @ViewBuilder
    private func buildRectangles(in geometry: GeometryProxy) -> some View {
        ForEach(viewModel.notes) { note in
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray)
                .aspectRatio(2/3, contentMode: .fit)
                .frame(width: 100)
                .overlay(
                    Text("\(note.name)")
                        .font(.largeTitle.bold())
                )
                .position(constantPositions[viewModel.notes.firstIndex(of: note) ?? 0])
        }
        .scaleEffect(scaleEffect * scaleEffectGestureState)
        .offset(panDistance + panDistanceGestureState)
        .rotationEffect(rotation + rotationGestureState)
        .zIndex(1000)
    }
    
    @ViewBuilder
    private func buildLines(in geometry: GeometryProxy) -> some View {
        ForEach(viewModel.notes) { note in
            ForEach(note.linkedNotes) { linkedNote in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 200, y: 400))
                }
                .stroke(Color.blue)
            }
        }
        .zIndex(0)
    }
    
    private func zoomToFit() {
        let rotationNormalized = rotation.degrees.isNormal ? rotation.degrees : 0
        withAnimation {
            panDistance = .zero
            rotation = .degrees(Double((Int(rotationNormalized) / 360) * 360))
            scaleEffect = 1
        }
    }
}
