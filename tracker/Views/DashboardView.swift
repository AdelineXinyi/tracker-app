//
//  DashboardView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        TabView {
            NavigationView {
                JobListView()
            }
            .tabItem {
                Label("Jobs", systemImage: "briefcase")
            }
            
            NavigationView {
                ResearchListView()
            }
            .tabItem {
                Label("Research", systemImage: "graduationcap")
            }
            
            NavigationView {
                SkillListView()
            }
            .tabItem {
                Label("Skills", systemImage: "book")
            }
        }
    }
}

//// 保留预览提供程序
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
