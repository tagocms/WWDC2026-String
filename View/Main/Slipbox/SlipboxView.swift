//
//  SlipboxView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 13/02/26.
//

import SwiftData
import SwiftUI

struct SlipboxView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Data
    @Bindable var slipbox: Slipbox
    @State private var viewModel: SlipboxViewModel!
    
    // MARK: - UI State
    @State private var isBeingCreated: Bool = false
    @State private var isAlertPresented: Bool = false
    @FocusState private var isFocused: Bool
    @State private var nameTextFieldSelection: TextSelection?
    
    // MARK: - View
    var body: some View {
        Group {
            if let viewModel {
                let bindableViewModel = Bindable(viewModel)
                buildForm(with: bindableViewModel)
                    .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
                        viewModel.buildAlertActions {
                            dismiss()
                        }
                    } message: {
                        Text(viewModel.alertMessage)
                    }
            } else {
                ProgressView().font(.largeTitle)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SlipboxViewModel(modelContext, slipbox: slipbox)
                if isBeingCreated {
                    isFocused = true
                }
            }
        }
        .onChange(of: isFocused) { _, newValue in
            guard let viewModel else { return }
            guard !viewModel.selectedSlipboxName.isEmpty, isBeingCreated else { return }
            // Selects the name text for newly created slipboxes
            nameTextFieldSelection = TextSelection(
                range: viewModel.selectedSlipboxName.startIndex..<viewModel.selectedSlipboxName.endIndex
            )
            isBeingCreated = false
        }
        .onChange(of: isFocused) { oldValue, newValue in
            guard let viewModel else { return }
            // Cleans the text for selected slipbox's name
            if oldValue, !newValue {
                viewModel.selectedSlipboxName = viewModel.selectedSlipboxName.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Initializer
    init(_ slipbox: Slipbox, isBeingCreated: Bool = false) {
        self._slipbox = Bindable(slipbox)
        self._isBeingCreated = State(initialValue: isBeingCreated)
    }
    
    // MARK: - Builder methods
    private func buildForm(with bindableViewModel: Bindable<SlipboxViewModel>) -> some View {
        Form {
            Section("Slipbox") {
                TextField("Name", text: bindableViewModel.selectedSlipboxName, selection: $nameTextFieldSelection)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .submitLabel(.done)
                Picker("Parent Slipbox", selection: bindableViewModel.selectedSlipboxParentSlipbox) {
                    Text("Root")
                        .tag(nil as Slipbox?)
                    ForEach(viewModel.slipboxes.sorted()) { possibleParent in
                        if slipbox.isParentSlipboxValid(possibleParent) {
                            Text(possibleParent.name)
                                .tag(possibleParent)
                        }
                    }
                }
            }
            
            Button("Delete slipbox", systemImage: "trash", role: .destructive) {
                viewModel.controlModels.slipboxToDelete = slipbox
                isAlertPresented = true
            }
            .foregroundStyle(.red)
        }
    }
}
