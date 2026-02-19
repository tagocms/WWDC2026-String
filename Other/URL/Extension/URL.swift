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
    
    static func createDeepLinkURL(data: PersistentIdentifier) -> URL? {
        var components = URLComponents()
        components.scheme = Self.customScheme
        components.host = Self.customHost
        components.path = Self.customPath
        
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(data) {
            components.queryItems = [
                URLQueryItem(name: "data", value: encodedData.base64EncodedString())
            ]
        }
        return components.url
    }
}
