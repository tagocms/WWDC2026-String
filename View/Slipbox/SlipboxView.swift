//
//  SlipboxView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 13/02/26.
//

import SwiftData
import SwiftUI

struct SlipboxView: View {
    // MARK: - Dismiss
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Data
    let slipbox: Slipbox
    @Bindable private var viewModel: MainViewModel
    
    // MARK: - Data UI State
    @State private var name: String
    @State private var parentSlipbox: Slipbox?
    
    // MARK: - UI State
    @State private var isAlertPresented: Bool = false
    
    // MARK: - View
    var body: some View {
        Form {
            Section("Slipbox") {
                TextField("Name", text: $name)
                Picker("Parent Slipbox", selection: $parentSlipbox) {
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
            
            Button("Delete slipbox", role: .destructive) {
                viewModel.slipboxToDelete = slipbox
                isAlertPresented = true
            }
        }
        .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
            viewModel.buildAlertActions {
                dismiss()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: name) { oldValue, newValue in
            if slipbox.isNameValid(newValue, allSlipboxes: viewModel.slipboxes) {
                name = newValue
            } else {
                name = oldValue
            }
        }
        .onDisappear(perform: saveChanges)
    }
    
    // MARK: - Initializer
    init(_ slipbox: Slipbox, viewModel: MainViewModel) {
        self.slipbox = slipbox
        self._name = State(initialValue: slipbox.name)
        self._parentSlipbox = State(initialValue: slipbox.parentSlipbox)
        self._viewModel = Bindable(viewModel)
    }
    
    // MARK: - Auxiliary functions
    private func saveChanges() {
        slipbox.setName(name, allSlipboxes: viewModel.slipboxes)
        slipbox.setParentSlipbox(parentSlipbox)
    }
}
