//
//  FeatureTips.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 28/02/26.
//

import TipKit

struct OnboardingTip: Tip {
    var title: Text {
        Text("Welcome to String!")
    }
    
    var message: Text {
        Text("In String, you can create notes and link them together, as well as using tags to categorize them.")
    }
    
    var image: Image? {
        Image(systemName: "document.on.document")
    }
}

struct SettingsTip: Tip {
    @Parameter
    static var isOnboardingShown: Bool = false
    
    var title: Text {
        Text("Customize your experience")
    }
    
    var message: Text {
        Text("You can change the theme, color, display style and other options in the settings sheet.")
    }
    
    var image: Image? {
        Image(systemName: "gear")
    }
    
    var rules: [Rule] {
        #Rule(Self.$isOnboardingShown) { value in
            value == true
        }
    }
}

struct NoteControlTip: Tip {
    @Parameter
    static var isSettingsShown: Bool = true
    
    var title: Text {
        Text("Create notes and organize them")
    }
    
    var message: Text {
        Text("With these controls, you can add notes, slipboxes, filter the and change between linking and dragging mode.")
    }
    
    var image: Image? {
        Image(systemName: "ellipsis")
    }
    
    var rules: [Rule] {
        #Rule(Self.$isSettingsShown) { value in
            value == true
        }
    }
}

struct DraggingModeTip: Tip {
    var title: Text {
        Text("Toggle between dragging or linking notes")
    }
    
    var message: Text {
        Text("In dragging mode, you can organize your notes in the way that works best for you. In linking mode, you can link them together directly from the map!")
    }
    
    var image: Image? {
        Image(systemName: "hand.draw")
    }
}

struct UIControlsTip: Tip {
    var title: Text {
        Text("Control the map view")
    }
    
    var message: Text {
        Text("With getures or with the controls, zoom in and out, pan around the notes and even rotate the map!")
    }
    
    var image: Image? {
        Image(systemName: "square.on.square.squareshape.controlhandles")
    }
}

struct GetStartedTip: Tip {
    var title: Text {
        Text("Get started now!")
    }
    
    var message: Text {
        Text("Select the 'Welcome! Start here' note for more information about the app and how to make the most out of it!")
    }
    
    var image: Image? {
        Image(systemName: "document")
    }
}
