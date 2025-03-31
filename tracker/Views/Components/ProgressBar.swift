//
//  ProgressBar.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI

struct ProgressBar: View {
    var value: Float
    var color: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 8)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(value)*geometry.size.width, geometry.size.width),
                           height: 8)
                    .foregroundColor(color)
                    .animation(.linear, value: value)
            }
            .cornerRadius(4)
        }
        .frame(height: 8)
    }
}
