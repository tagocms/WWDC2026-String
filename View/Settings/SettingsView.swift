//
//  SettingsView.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Constants
    static let userDefaultsColorKey = "colorKey"
    
    // MARK: - UI settings
    @AppStorage("theme") private var theme: Theme = .light
    @AppStorage("colorKey") private var accentColor: Color = Color.accentColor
    @AppStorage("isMapViewEnabled") private var isMapViewEnabled: Bool = true
    
    @AppStorage("isShowingUIControls") private var isShowingUIControls: Bool = true
    @AppStorage("isCameraGesturesEnabled") private var isCameraGesturesEnabled: Bool = true
    @AppStorage("isControlGesturesEnabled") private var isControlGesturesEnabled: Bool = true
    
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
                ColorPicker("Accent color", selection: $accentColor.animation(), supportsOpacity: false)
                Toggle("Enable map view", isOn: $isMapViewEnabled.animation())
            }
            
            if isMapViewEnabled {
                Section("Map View Options") {
                    Toggle("Show UI Controls", isOn: $isShowingUIControls.animation())
                    Toggle("Enable camera gestures", isOn: $isCameraGesturesEnabled)
                    Toggle("Enable control gestures", isOn: $isControlGesturesEnabled)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    SettingsView()
}
