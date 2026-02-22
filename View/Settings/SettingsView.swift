//
//  SettingsView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Constants
    static let userDefaultsColorKey = "colorKey"
    
    // MARK: - UI settings
    @AppStorage("theme") private var theme: Theme = .system
    @AppStorage("isShowingUIControls") private var isShowingUIControls: Bool = true
    @AppStorage("automaticTagRemoval") private var automaticTagRemoval: Bool = false
    @AppStorage("automaticLinkedNoteRemoval") private var automaticLinkedNoteRemoval: Bool = false
    @AppStorage("colorKey") private var accentColor: Color = Color.accentColor
    
    var body: some View {
        Form {
            Section("User Interface") {
                Picker("Theme", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue)
                            .tag(theme)
                    }
                }
                ColorPicker("Accent color", selection: $accentColor, supportsOpacity: false)
                Toggle("Show UI Controls", isOn: $isShowingUIControls)
                Toggle("Automatic Tag Removal", isOn: $automaticTagRemoval)
                Toggle("Automatic Linked Note Removal", isOn: $automaticLinkedNoteRemoval)
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    SettingsView()
}
