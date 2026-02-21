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
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Data
    @Bindable var slipbox: Slipbox
    @State private var viewModel: SlipboxViewModel!
    
    // MARK: - UI State
    @State private var isAlertPresented: Bool = false
    
    // MARK: - View
    var body: some View {
        Group {
            if let bindableViewModel = Binding($viewModel) {
                buildForm(bindableViewModel)
            } else {
                ProgressView().font(.largeTitle)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SlipboxViewModel(modelContext, slipbox: slipbox)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $isAlertPresented) {
            viewModel.buildAlertActions {
                dismiss()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: viewModel.name) { oldValue, newValue in
            if slipbox.isNameValid(newValue, allSlipboxes: viewModel.slipboxes) {
                viewModel.name = newValue
            } else {
                viewModel.name = oldValue
            }
        }
    }
    
    // MARK: - Initializer
    init(_ slipbox: Slipbox) {
        self.slipbox = slipbox
    }
    
    // MARK: - Builder methods
    private func buildForm(_ bindableViewModel: Binding<SlipboxViewModel>) -> some View {
        Form {
            Section("Slipbox") {
                TextField("Name", text: bindableViewModel.name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("Parent Slipbox", selection: bindableViewModel.parentSlipbox) {
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
    }
}
