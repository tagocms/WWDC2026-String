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
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.largeTitle)
            Text(text)
                .font(.headline.bold())
        }
    }
}
