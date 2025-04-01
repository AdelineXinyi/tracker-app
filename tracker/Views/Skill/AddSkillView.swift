//
//  AddSkillView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

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
    @Environment(\.dismiss) private var dismiss
    
    // Form State
    @State private var skillName = ""
    @State private var startDate = Date()
    @State private var targetDate = Date().addingTimeInterval(86400 * 30)
    @State private var initialProgress: Float = 0.0
    @State private var resources = ""
    
    // Validation
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var minimumTargetDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Skill Information") {
                    TextField("Skill Name", text: $skillName)
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading) {
                        Text("Initial Progress: \(Int(clampedProgress * 100))%")
                            .font(.subheadline)
                        
                        Slider(value: $initialProgress, in: 0...1, step: 0.05)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Time Frame") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Target Date", selection: $targetDate, in: startDate..., displayedComponents: .date)
                }
                
                Section("Learning Resources") {
                    TextEditor(text: $resources)
                        .frame(minHeight: 100)
                        .overlay(
                            resources.isEmpty ?
                            Text("Books, tutorials, references...\n(One per line)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4) : nil,
                            alignment: .topLeading
                        )
                }
                
                Section {
                    Button("Add Skill") {
                        addSkill()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("New Skill")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        addSkill()
                    }
                    .disabled(!formIsValid)
                    .buttonStyle(.plain)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .presentationBackground(.clear)
    }
    
    // MARK: - Computed Properties
    private var clampedProgress: Float {
        max(0, min(initialProgress, 1.0))
    }
    
    private var formIsValid: Bool {
        !skillName.trimmed.isEmpty && targetDate >= startDate
    }
    
    // MARK: - Core Data Operations
    private func addSkill() {
        guard formIsValid else {
            alertMessage = "Please complete all required fields"
            showingAlert = true
            return
        }
        
        viewContext.perform {
            let newSkill = SkillLearning(context: viewContext)
            newSkill.skillName = skillName.trimmed
            newSkill.startDate = startDate
            newSkill.targetDate = targetDate
            newSkill.progress = clampedProgress
            newSkill.resources = resources.trimmed.isEmpty ? nil : resources.trimmed
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                alertMessage = "Failed to save skill: \(error.localizedDescription)"
                showingAlert = true
                viewContext.rollback()
            }
        }
    }
}

// MARK: - Previews
#Preview {
    AddSkillView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
