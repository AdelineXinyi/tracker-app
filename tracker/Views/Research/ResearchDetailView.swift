//
//  ResearchDetailView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct ResearchDetailView: View {
    @ObservedObject var research: ResearchApplication
    
    var body: some View {
        Form {
            Section(header: Text("Institution")) {
                Text(research.universityName)
                Text(research.professorName)
            }
            
            Section(header: Text("Research Details")) {
                Text(research.researchField)
                Text(research.applyDate.formatted(date: .abbreviated, time: .omitted))
                Text(research.status)
            }
        }
        .navigationTitle("Research Details")
    }
}

struct ResearchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let research = ResearchApplication(context: context)
        research.universityName = "Stanford"
        research.professorName = "Dr. Smith"
        research.researchField = "Computer Science"
        research.applyDate = Date()
        research.status = "Submitted"
        
        return NavigationView {
            ResearchDetailView(research: research)
        }
    }
}
