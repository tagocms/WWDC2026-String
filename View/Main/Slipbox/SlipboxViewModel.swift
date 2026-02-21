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
    // MARK: - Data UI State
    var name: String {
        get {
            selectedSlipbox?.name ?? ""
        }
        set {
            selectedSlipbox?.setName(newValue, allSlipboxes: slipboxes)
        }
    }
    var parentSlipbox: Slipbox? {
        get {
            selectedSlipbox?.parentSlipbox
        }
        set {
            selectedSlipbox?.setParentSlipbox(newValue)
        }
    }
    
    init(_ modelContext: ModelContext, slipbox: Slipbox) {
        super.init(modelContext)
        self.selectedSlipbox = slipbox
    }
}
