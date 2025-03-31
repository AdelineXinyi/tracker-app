//
//  SkillDetailView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct SkillDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var skill: SkillLearning
    
    @State private var showingEditView = false
    @State private var showingResourceSheet = false
    @State private var newResource = ""
    
    // Computed properties for date formatting
    var formattedStartDate: String {
        skill.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"
    }
    
    var formattedTargetDate: String {
        skill.targetDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set"
    }
    
    var daysRemaining: Int {
        guard let target = skill.targetDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
    }
    
    var progressStatus: String {
        switch skill.progress {
        case 0..<0.3:
            return "Just Started"
        case 0.3..<0.7:
            return "In Progress"
        case 0.7..<1:
            return "Almost There"
        case 1:
            return "Completed"
        default:
            return "Unknown"
        }
    }
    
    var resources: [String] {
        (skill.resources ?? "").components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(skill.skillName ?? "Unknown Skill")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(progressStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Progress Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Progress: \(Int(skill.progress * 100))%")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(daysRemaining) days left")
                            .foregroundColor(daysRemaining < 7 ? .red : .secondary)
                    }
                    
                    ProgressBar(value: skill.progress)
                        .frame(height: 12)
                    
                    Slider(value: $skill.progress, in: 0...1, step: 0.01)
                        .accentColor(progressColor)
                        .onChange(of: skill.progress) { _ in
                            saveChanges()
                        }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Dates Section
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedStartDate)
                            .font(.subheadline)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading) {
                        Text("Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedTargetDate)
                            .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Resources Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Learning Resources")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingResourceSheet = true }) {
                            Image(systemName: "plus")
                                .font(.subheadline)
                        }
                    }
                    
                    if resources.isEmpty {
                        Text("No resources added yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(resources, id: \.self) { resource in
                            HStack {
                                Link(destination: URL(string: resource) ?? URL(string: "https://example.com")!) {
                                    Text(resource)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    removeResource(resource)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditSkillView(skill: skill)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingResourceSheet) {
            resourceInputSheet
        }
    }
    
    private var progressColor: Color {
        switch skill.progress {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<1: return .yellow
        case 1: return .green
        default: return .blue
        }
    }
    
    private var resourceInputSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Resource URL")) {
                    TextField("https://example.com", text: $newResource)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button("Add Resource") {
                        addResource()
                        showingResourceSheet = false
                    }
                    .disabled(newResource.isEmpty || !newResource.isValidURL)
                }
            }
            .navigationTitle("Add Resource")
            .navigationBarItems(trailing: Button("Cancel") {
                showingResourceSheet = false
            })
        }
    }
    
    private func saveChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving skill: \(error.localizedDescription)")
        }
    }
    
    private func addResource() {
        var currentResources = resources
        currentResources.append(newResource)
        skill.resources = currentResources.joined(separator: "\n")
        newResource = ""
        saveChanges()
    }
    
    private func removeResource(_ resource: String) {
        var currentResources = resources
        currentResources.removeAll { $0 == resource }
        skill.resources = currentResources.joined(separator: "\n")
        saveChanges()
    }
}

// MARK: - Edit Skill View

struct EditSkillView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var skill: SkillLearning
    
    @State private var skillName: String
    @State private var startDate: Date
    @State private var targetDate: Date
    
    init(skill: SkillLearning) {
        self.skill = skill
        _skillName = State(initialValue: skill.skillName ?? "")
        _startDate = State(initialValue: skill.startDate ?? Date())
        _targetDate = State(initialValue: skill.targetDate ?? Date().addingTimeInterval(86400 * 30))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Skill Info")) {
                    TextField("Skill Name", text: $skillName)
                }
                
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Target Date", selection: $targetDate, in: startDate..., displayedComponents: .date)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(skillName.isEmpty)
                }
            }
            .navigationTitle("Edit Skill")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveChanges() {
        skill.skillName = skillName
        skill.startDate = startDate
        skill.targetDate = targetDate
        do {
            try viewContext.save()
        } catch {
            print("Error saving skill: \(error.localizedDescription)")
        }
    }
}

// MARK: - URL Validation Extension

extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - Previews

struct SkillDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let skill = SkillLearning(context: context)
        skill.skillName = "SwiftUI"
        skill.startDate = Date().addingTimeInterval(-86400 * 10)
        skill.targetDate = Date().addingTimeInterval(86400 * 20)
        skill.progress = 0.65
        skill.resources = """
        https://developer.apple.com/tutorials/swiftui
        https://www.hackingwithswift.com/quick-start/swiftui
        """
        
        return NavigationView {
            SkillDetailView(skill: skill)
                .environment(\.managedObjectContext, context)
        }
    }
}
