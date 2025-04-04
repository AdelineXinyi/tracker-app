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
    @State private var showingEditView = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let statusOptions = ["Applied", "Interview", "Offer", "Rejected"]
    
    var body: some View {
        Form {
            Section(header: Text("Job Details")) {
                Text(job.companyName)
                Text(job.positionName)
                Text(job.applyDate.formatted(date: .abbreviated, time: .omitted))
                
                if let skills = job.requiredSkills, !skills.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Required Skills:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(skills.replacingOccurrences(of: "\n", with: ", "))
                    }
                }
            }
            
            Section(header: Text("Status")) {
                Text(job.status)
                    .foregroundColor(statusColor(for: job.status))
            }
        }
        .navigationTitle("Job Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                JobEditView(job: job, statusOptions: statusOptions)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Applied": return .blue
        case "Interview": return .orange
        case "Offer": return .green
        case "Rejected": return .red
        default: return .blue
            
        }
    }
    
    struct JobEditView: View {
        @ObservedObject var job: JobApplication
        let statusOptions: [String]
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            Form {
                Section(header: Text("Job Details")) {
                    TextField("Company Name", text: $job.companyName)
                    TextField("Position", text: $job.positionName)
                    DatePicker("Apply Date", selection: $job.applyDate, displayedComponents: .date)
                    
                    TextEditor(text: Binding(
                        get: { job.requiredSkills ?? "" },
                        set: { job.requiredSkills = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                    .overlay(
                        (job.requiredSkills?.isEmpty ?? true) ?
                        Text("programming language...\n(One per line)")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4) : nil,
                        alignment: .topLeading
                    )
                }
                
                Section(header: Text("Status")) {
                    Picker("Status", selection: $job.status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        CoreDataHelper.saveContext()
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                            Spacer()
                        }
                    }
                    .disabled(job.companyName.isEmpty || job.positionName.isEmpty)
                }
            }
            .navigationTitle("Edit Job")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
            job.requiredSkills = "Swift\nUIKit\nCoreData"
            
            return NavigationStack {
                JobDetailView(job: job)
                    .environment(\.managedObjectContext, context)
            }
        }
    }
}
