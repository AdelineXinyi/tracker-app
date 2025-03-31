//
//  StatusPill.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI

struct StatusPill: View {
    let status: String
    var color: Color {
        switch status {
        case "Applied": return .blue
        case "Interview": return .orange
        case "Offer": return .green
        case "Rejected": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(10)
    }
}
