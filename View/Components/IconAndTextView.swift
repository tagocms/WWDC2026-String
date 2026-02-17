//
//  IconAndTextView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

struct IconAndTextView: View {
    let iconName: String
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.largeTitle)
            Text(text)
                .font(.headline.bold())
                .lineLimit(1)
        }
        .frame(maxWidth: 100)
        .opacity(isSelected ? 1 : 0.6)
    }
    
    init(iconName: String, text: String, isSelected: Bool = true) {
        self.iconName = iconName
        self.text = text
        self.isSelected = isSelected
    }
}
