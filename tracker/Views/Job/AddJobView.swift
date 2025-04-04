//
//  AddJobView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct AddJobView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var companyName = ""
    @State private var positionName = ""
    @State private var applyDate = Date()
    @State private var status = "Applied"
    @State private var requiredSkills = ""
    
    let statusOptions = ["Applied", "Interview", "Offer", "Rejected"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Job Details")) {
                    TextField("Company Name", text: $companyName)
                    TextField("Position", text: $positionName)
                    DatePicker("Apply Date", selection: $applyDate, displayedComponents: .date)
                    TextEditor(text: $requiredSkills)
                        .frame(minHeight: 100)
                        .overlay(
                            requiredSkills.isEmpty ?
                            Text("programming language...\n(One per line)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4) : nil,
                            alignment: .topLeading
                        )
                }
                
                Section(header: Text("Status")) {
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: addJob) {
                        HStack {
                            Spacer()
                            Text("Save")
                            Spacer()
                        }
                    }
                    .disabled(companyName.isEmpty || positionName.isEmpty)
                }
            }
            .navigationTitle("Add Job")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func addJob() {
        withAnimation {
            let newJob = JobApplication(context: viewContext)
            newJob.companyName = companyName
            newJob.positionName = positionName
            newJob.applyDate = applyDate
            newJob.status = status
            newJob.requiredSkills = requiredSkills
            
            CoreDataHelper.saveContext()
            presentationMode.wrappedValue.dismiss()
        }
    }
}
