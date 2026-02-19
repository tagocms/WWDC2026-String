//
//  File.swift
//  CreativeChallenge
//
//  Created by Tiago Camargo Maciel dos Santos on 19/02/26.
//

import Foundation
import SwiftData

extension URL {
    static let customScheme = "tiagosantosURL"
    static let customHost = "com.tiago.santos"
    static let customPath = "/noteview"
    
    static func createDeepLinkURL(data: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = Self.customScheme
        components.host = Self.customHost
        components.path = Self.customPath
        components.queryItems = [
            URLQueryItem(name: "data", value: data.uuidString)
        ]
        return components.url
    }
}
