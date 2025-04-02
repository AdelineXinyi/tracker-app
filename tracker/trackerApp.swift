//
//  trackerApp.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//
import SwiftUI

@main
struct trackerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
        }
    }
}
