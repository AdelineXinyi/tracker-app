//
//  DateHelper.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import Foundation

struct DateHelper {
    static func formattedDate(_ date: Date, format: String = "MMM d, yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    static func daysBetween(start: Date, end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
