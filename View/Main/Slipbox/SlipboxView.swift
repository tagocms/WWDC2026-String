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
    @State private var isAlertPresented: Bool = false
    
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
            }
        }
    }
    
    // MARK: - Initializer
    init(_ slipbox: Slipbox) {
        self._slipbox = Bindable(slipbox)
    }
    
    // MARK: - Builder methods
    private func buildForm(with bindableViewModel: Bindable<SlipboxViewModel>) -> some View {
        Form {
            Section("Slipbox") {
                TextField("Name", text: bindableViewModel.selectedSlipboxName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
            
            Button("Delete slipbox", role: .destructive) {
                viewModel.controlModels.slipboxToDelete = slipbox
                isAlertPresented = true
            }
        }
    }
}
