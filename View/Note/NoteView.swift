//
//  SwiftUIView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 08/02/26.
//

import SwiftUI

struct NoteView: View {
    let note: Note
    
    var body: some View {
        Text(note.name)
            .font(.largeTitle.bold())
    }
}
