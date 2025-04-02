//
//  UserDefaults+Extensions.swift
//  tracker
//
//  Created by xinyi li on 4/2/25.
//

import SwiftUI

extension UserDefaults {
    private enum Keys {
        static let appBackgroundColor = "appBackgroundColor"
    }
    
    static var appBackgroundColor: Color {
        get {
            if let colorData = standard.data(forKey: Keys.appBackgroundColor),
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return Color("AppBackground") // Default from assets
        }
        set {
            let uiColor = UIColor(newValue)
            if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
                standard.set(colorData, forKey: Keys.appBackgroundColor)
            }
        }
    }
}
