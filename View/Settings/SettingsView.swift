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
    @AppStorage("theme") private var theme: Theme = .light
    @AppStorage("isShowingUIControls") private var isShowingUIControls: Bool = true
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
                .tint(accentColor)
                .id(accentColor)
                ColorPicker("Accent color", selection: $accentColor, supportsOpacity: false)
                Toggle("Show UI Controls", isOn: $isShowingUIControls)
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    SettingsView()
}
