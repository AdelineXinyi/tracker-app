//
//  AddResearchView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct AddResearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var universityName = ""
    @State private var professorName = ""
    @State private var researchField = ""
    @State private var status = "Preparing"
    
    let statusOptions = ["Preparing", "Submitted", "Under Review", "Accepted", "Rejected"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Institution Info")) {
                    TextField("University Name", text: $universityName)
                    TextField("Professor Name", text: $professorName)
                }
                
                Section(header: Text("Research Details")) {
                    TextField("Research Field", text: $researchField)
                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status)
                        }
                    }
                }
                
                Section {
                    Button("Save") {
                        let newResearch = ResearchApplication(context: viewContext)
                        newResearch.universityName = universityName
                        newResearch.professorName = professorName
                        newResearch.researchField = researchField
                        newResearch.applyDate = Date()
                        newResearch.status = status
                        
                        do {
                            try viewContext.save()
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Error saving research: \(error.localizedDescription)")
                        }
                    }
                    .disabled(universityName.isEmpty || professorName.isEmpty || researchField.isEmpty)
                }
            }
            .navigationTitle("Add Research")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct AddResearchView_Previews: PreviewProvider {
    static var previews: some View {
        AddResearchView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
