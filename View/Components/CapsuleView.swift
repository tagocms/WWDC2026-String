//
//  CapsuleView.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 28/02/26.
//

import SwiftUI

struct CapsuleView: View {
    @AppStorage("colorKey") private var accentColor: Color = .accentColor
    let name: String
    let standardSpacingAndPadding: CGFloat = 8
    
    var body: some View {
        Text(name)
            .padding(.horizontal, standardSpacingAndPadding)
            .padding(.vertical, standardSpacingAndPadding / 2)
            .background(accentColor.opacity(0.2))
            .clipShape(.capsule)
            .foregroundStyle(accentColor)
    }
}
