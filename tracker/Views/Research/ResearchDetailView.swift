//
//  ResearchDetailView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct ResearchDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var research: ResearchApplication
    @State private var showingEditView = false
    
    let statusOptions = ["Preparing", "Submitted", "Under Review", "Accepted", "Rejected"]
    
    var body: some View {
        Form {
            Section(header: Text("Institution")) {
                Text(research.universityName )
                Text(research.professorName )
            }
            
            Section(header: Text("Research Details")) {
                Text(research.researchField )
                Text(research.applyDate.formatted(date: .abbreviated, time: .omitted) )
                Text(research.status)
            }
        }
        .navigationTitle("Research Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                ResearchEditView(research: research, statusOptions: statusOptions)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

struct ResearchEditView: View {
    @ObservedObject var research: ResearchApplication
    let statusOptions: [String]
    @Environment(\.dismiss) private var dismiss
    
    // Create bindings with default values
    private var universityName: Binding<String> {
        Binding(
            get: { research.universityName  },
            set: { research.universityName = $0 }
        )
    }
    
    private var professorName: Binding<String> {
        Binding(
            get: { research.professorName },
            set: { research.professorName = $0 }
        )
    }
    
    private var researchField: Binding<String> {
        Binding(
            get: { research.researchField },
            set: { research.researchField = $0 }
        )
    }
    
    private var status: Binding<String> {
        Binding(
            get: { research.status  },
            set: { research.status = $0 }
        )
    }
    
    private var applyDate: Binding<Date> {
        Binding(
            get: { research.applyDate },
            set: { research.applyDate = $0 }
        )
    }
    
    var body: some View {
        Form {
            Section(header: Text("Institution Info")) {
                TextField("University Name", text: universityName)
                TextField("Professor Name", text: professorName)
            }
            
            Section(header: Text("Research Details")) {
                DatePicker("Apply Date", selection: applyDate, displayedComponents: .date)
                TextField("Research Field", text: researchField)
                Picker("Status", selection: status) {
                    ForEach(statusOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }
            
            Section {
                Button("Save Changes") {
                    dismiss()
                }
                .disabled(universityName.wrappedValue.isEmpty ||
                          professorName.wrappedValue.isEmpty ||
                          researchField.wrappedValue.isEmpty)
            }
        }
        .navigationTitle("Edit Research")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
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
        
        return NavigationStack {
            ResearchDetailView(research: research)
                .environment(\.managedObjectContext, context)
        }
    }
}
