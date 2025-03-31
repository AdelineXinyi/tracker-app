//
//  JobDetailView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct JobDetailView: View {
    @ObservedObject var job: JobApplication
    
    var body: some View {
        Form {
            Section(header: Text("Company Info")) {
                Text(job.companyName)
                Text(job.positionName)
            }
            
            Section(header: Text("Application Details")) {
                Text(job.applyDate.formatted(date: .abbreviated, time: .omitted))
                Text(job.status)
            }
            
            if !job.skillsArray.isEmpty {
                Section(header: Text("Required Skills")) {
                    ForEach(job.skillsArray, id: \.self) { skill in
                        Text(skill)
                    }
                }
            }
        }
        .navigationTitle("Job Details")
    }
}

struct JobDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let job = JobApplication(context: context)
        job.companyName = "Apple"
        job.positionName = "iOS Developer"
        job.applyDate = Date()
        job.status = "Applied"
        job.requiredSkills = "Swift,UIKit,CoreData"
        
        return NavigationView {
            JobDetailView(job: job)
        }
    }
}
