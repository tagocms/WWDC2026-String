//
//  SlipboxViewModel.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 20/02/26.
//

import SwiftData
import SwiftUI

@Observable
@MainActor
final class SlipboxViewModel: MainViewModel {
    // MARK: - Data and UI State
    let slipbox: Slipbox
    var selectedSlipboxName: String {
        get { slipbox.name }
        set { slipbox.setName(newValue, allSlipboxes: slipboxes) }
    }
    var selectedSlipboxParentSlipbox: Slipbox? {
        get { slipbox.parentSlipbox }
        set { slipbox.setParentSlipbox(newValue) }
    }
    
    // MARK: - Initializer
    init(_ modelContext: ModelContext, slipbox: Slipbox) {
        self.slipbox = slipbox
        super.init(modelContext)
    }
}
