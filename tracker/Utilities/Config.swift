//
//  Config.swift
//  tracker
//
//  Created by xinyi li on 4/2/25.
//

import Foundation

enum Config {
    static var deepInfraKey: String {
          guard let value = Bundle.main.object(forInfoDictionaryKey: "DEEPINFRA_API_KEY") as? String else {
              fatalError("DEEPINFRA_API_KEY not found in Info.plist!")
          }
          return value
      }
}
