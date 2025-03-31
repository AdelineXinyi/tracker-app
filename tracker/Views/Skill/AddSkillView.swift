//
//  AddSkillView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct AddSkillView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // Form State
    @State private var skillName = ""
    @State private var startDate = Date()
    @State private var targetDate = Date().addingTimeInterval(86400 * 30) // Default 30 days from now
    @State private var initialProgress: Float = 0.0
    @State private var resources = ""
    
    // Validation State
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Minimum date calculation
    private var minimumTargetDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Skill Information")) {
                    TextField("Skill Name", text: $skillName)
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading) {
                        Text("Initial Progress: \(Int(initialProgress * 100))%")
                            .font(.subheadline)
                        
                        Slider(value: $initialProgress, in: 0...1, step: 0.05)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Time Frame")) {
                    DatePicker("Start Date",
                              selection: $startDate,
                              displayedComponents: .date)
                        .onChange(of: startDate) { _, newValue in
                            if targetDate < newValue {
                                targetDate = minimumTargetDate
                            }
                        }
                    
                    DatePicker("Target Date",
                              selection: $targetDate,
                              in: startDate...,
                              displayedComponents: .date)
                }
                
                Section(header: Text("Learning Resources (one per line)")) {
                    TextEditor(text: $resources)
                        .frame(minHeight: 100)
                        .font(.body)
                }
                
                Section {
                    Button(action: addSkill) {
                        HStack {
                            Spacer()
                            Text("Add Skill")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .disabled(skillName.isEmpty)
                }
            }
            .navigationTitle("New Skill")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    addSkill()
                }
                .disabled(skillName.isEmpty)
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Validation Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                    )
            }
        }
    }
    
    private func addSkill() {
        // Validate target date
        guard targetDate >= startDate else {
            alertMessage = "Target date must be after start date"
            showingAlert = true
            return
        }
        
        // Validate progress
        guard initialProgress >= 0 && initialProgress <= 1 else {
            alertMessage = "Progress must be between 0% and 100%"
            showingAlert = true
            return
        }
        
        withAnimation {
            let newSkill = SkillLearning(context: viewContext)
            
            newSkill.skillName = skillName.trimmingCharacters(in: .whitespacesAndNewlines)
            newSkill.startDate = startDate
            newSkill.targetDate = targetDate
            newSkill.progress = initialProgress
            newSkill.resources = resources.trimmingCharacters(in: .whitespacesAndNewlines)
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                alertMessage = "Error saving skill: \(nsError.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Previews

struct AddSkillView_Previews: PreviewProvider {
    static var previews: some View {
     
        return AddSkillView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
