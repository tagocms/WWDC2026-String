//
//  SlipboxView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 13/02/26.
//

import SwiftData
import SwiftUI

struct SlipboxView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Data
    let slipbox: Slipbox
    @Bindable private var viewModel: MainViewModel
    
    // MARK: - UI State
    @State private var name: String
    @State private var parentSlipbox: Slipbox?
    @State private var isAlertActive: Bool = false
    
    var body: some View {
        Form {
            Section("Slipbox") {
                TextField("Name", text: $name)
                Picker("Parent Slipbox", selection: $parentSlipbox) {
                    Text("Root")
                        .tag(nil as Slipbox?)
                    ForEach(viewModel.slipboxes.sorted()) { possibleParent in
                        if slipbox != possibleParent {
                            Text(possibleParent.name)
                                .tag(possibleParent)
                        }
                    }
                }
            }
            
            Button("Delete slipbox", role: .destructive) {
                viewModel.slipboxToDelete = slipbox
                viewModel.isAlertPresented = true
            }
        }
        .alert(viewModel.alertTitle, isPresented: $isAlertActive) {
            viewModel.buildAlertActions {
                dismiss()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: name) { oldValue, newValue in
            if Slipbox.isNameValid(newValue) {
                name = newValue
            } else {
                name = oldValue
            }
        }
        .onDisappear {
            slipbox.setName(name)
            slipbox.setParentSlipbox(parentSlipbox)
        }
    }
    
    init(_ slipbox: Slipbox, viewModel: MainViewModel) {
        self.slipbox = slipbox
        self._name = State(initialValue: slipbox.name)
        self._parentSlipbox = State(initialValue: slipbox.parentSlipbox)
        self._viewModel = Bindable(viewModel)
    }
}
