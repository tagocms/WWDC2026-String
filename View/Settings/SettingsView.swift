//
//  SettingsView.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 12/02/26.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - UI settings
//    @Environment(\.colorScheme)
    @AppStorage("theme") private var theme: Theme = .system
    @AppStorage("isShowingUIControls") private var isShowingUIControls: Bool = true
    @AppStorage("isUI3D") private var isUI3D: Bool = false
    
    var body: some View {
        Form {
            Section("User Interface") {
                Picker("Theme", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue)
                            .tag(theme)
                    }
                }
                Toggle("Show UI Controls", isOn: $isShowingUIControls)
                Toggle("3D Mode", isOn: $isUI3D)
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    SettingsView()
}
