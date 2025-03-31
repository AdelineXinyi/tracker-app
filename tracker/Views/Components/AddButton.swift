//
//  AddButton.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI

struct AddButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
