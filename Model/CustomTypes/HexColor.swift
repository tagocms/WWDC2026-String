//
//  HexColor.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 13/02/26.
//

public struct HexColor: Codable, Sendable {
    var red: Int { didSet { Self.safelySet(value: &red) } }
    var green: Int { didSet { Self.safelySet(value: &green) } }
    var blue: Int { didSet { Self.safelySet(value: &blue) } }
    var alpha: Int { didSet { Self.safelySet(value: &alpha) } }
    
    init(red: Int, green: Int, blue: Int, alpha: Int = 0xFF) {
        self.red = Self.safelyInitialize(value: red)
        self.green = Self.safelyInitialize(value: green)
        self.blue = Self.safelyInitialize(value: blue)
        self.alpha = Self.safelyInitialize(value: alpha)
    }
    
    static private func safelySet(value: inout Int) {
        if value > 0xFF {
            value = 0xFF
        } else if value < 0 {
            value = 0x00
        }
    }
    
    static private func safelyInitialize(value: Int) -> Int {
        var newValue = value
        Self.safelySet(value: &newValue)
        return newValue
    }
}

extension HexColor {
    static let black = HexColor(red: 0x00, green: 0x00, blue: 0x00)
    static let white = HexColor(red: 0xFF, green: 0xFF, blue: 0xFF)
}
