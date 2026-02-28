//
//  OnboardingView.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 28/02/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var show: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(.string)
                .resizable()
                .scaledToFit()
            
            Text("Welcome to String!")
                .font(.largeTitle.bold())
            
            VStack(alignment: .leading, spacing: 12) {
                Text("""
                String was born out of the necessity to make studying more productive by taking notes in an **accessible and engaging** way, while also having capabilities that allow users to expand beyond the limitations of physical note-taking, such as linking notes and categorizing them by tags fluidly.
            """)
                
                Text("""
                **In String, you can:**
                1. **Create** new notes and slipboxes;
                2. **Link** notes together;
                3. Use **tags** for filtering and organizational purposes;
                4. Take notes in a **rich text-editor**, with inline linking and tagging;
            
                As if that weren't enough, the Map View provides users with a magical experience in **organizing notes spacially** or **linking them together** through gestures.
            """)
            }
            .font(.system(size: 20))
            .multilineTextAlignment(.leading)
            
            Button("Get started now") {
                withAnimation {
                    show = false
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.borderedProminent)
            .font(.title)
        }
        .containerRelativeFrame(.horizontal) { value, _ in
            value * 0.5
        }
    }
}
