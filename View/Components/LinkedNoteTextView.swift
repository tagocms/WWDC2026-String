//
//  LinkedNoteTextView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 28/02/26.
//

import SwiftUI

struct LinkedNoteTextView: View {
    @AppStorage("colorKey") private var accentColor: Color = .accentColor
    let name: String
    let standardSpacingAndPadding: CGFloat = 8
    
    var body: some View {
        Text(name)
            .padding(.trailing, standardSpacingAndPadding)
            .padding(.vertical, standardSpacingAndPadding / 2)
            .foregroundStyle(accentColor)
    }
}
