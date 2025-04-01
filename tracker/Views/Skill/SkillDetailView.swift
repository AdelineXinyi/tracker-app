import SwiftUI
import CoreData


struct SkillDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skill: SkillLearning
    
    @State private var showingEditView = false
    @State private var showingResourceSheet = false
    @State private var newResource = ""
    
    // Computed properties
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: skill.targetDate).day ?? 0
    }
    
    private var progressStatus: String {
        switch skill.progress {
        case 0..<0.3: return "Just Started"
        case 0.3..<0.7: return "In Progress"
        case 0.7..<1: return "Almost There"
        case 1: return "Completed"
        default: return "Unknown"
        }
    }
    
    private var resources: [String] {
        skill.resources?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(skill.skillName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(progressStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress Section
                progressSection
                
                // Dates Section
                datesSection
                
                // Resources Section
                resourcesSection
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditSkillView(skill: skill)
                .environment(\.managedObjectContext, viewContext)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingResourceSheet) {
            resourceInputSheet
                .presentationBackground(.clear)
        }
    }
    
    // MARK: - Subviews
    private var progressSection: some View {
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
                .tint(progressColor)
                .onChange(of: skill.progress) { _, _ in
                    saveChanges()
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
    
    private var datesSection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Started")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(skill.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack(alignment: .leading) {
                Text("Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(skill.targetDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Learning Resources")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingResourceSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            
            if resources.isEmpty {
                ContentUnavailableView(
                    "No Resources",
                    systemImage: "book"
                )
            } else {
                ForEach(resources, id: \.self) { resource in
                    HStack {
                        Text(resource)
                            .font(.subheadline)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button(action: { removeResource(resource) }) {
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
    
    private var resourceInputSheet: some View {
        NavigationStack {
            Form {
                Section("Add Resource") {
                    TextField("Book, video, article...", text: $newResource)
                        .autocapitalization(.sentences)
                }
                
                Section {
                    Button("Add") {
                        addResource()
                    }
                    .disabled(newResource.trimmed.isEmpty)
                }
            }
            .navigationTitle("Add Resource")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showingResourceSheet = false
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private var progressColor: Color {
        switch skill.progress {
        case 0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7..<1: return .yellow
        case 1: return .green
        default: return .blue
        }
    }
    
    private func saveChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }
    
    private func addResource() {
        let trimmed = newResource.trimmed
        guard !trimmed.isEmpty else { return }
        
        viewContext.perform {
            var current = resources
            current.append(trimmed)
            skill.resources = current.joined(separator: "\n")
            newResource = ""
            saveChanges()
            showingResourceSheet = false
        }
    }
    
    private func removeResource(_ resource: String) {
        viewContext.perform {
            skill.resources = resources
                .filter { $0 != resource }
                .joined(separator: "\n")
            saveChanges()
        }
    }
}

// MARK: - Edit View
struct EditSkillView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skill: SkillLearning
    
    @State private var skillName: String
    @State private var startDate: Date
    @State private var targetDate: Date
    
    init(skill: SkillLearning) {
        self.skill = skill
        _skillName = State(initialValue: skill.skillName)
        _startDate = State(initialValue: skill.startDate)
        _targetDate = State(initialValue: skill.targetDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Skill Info") {
                    TextField("Skill Name", text: $skillName)
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("Target Date", selection: $targetDate, in: startDate..., displayedComponents: .date)
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(skillName.trimmed.isEmpty)
                }
            }
            .navigationTitle("Edit Skill")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func saveChanges() {
        viewContext.perform {
            skill.skillName = skillName.trimmed
            skill.startDate = startDate
            skill.targetDate = targetDate
            do {
                try viewContext.save()
            } catch {
                print("Save error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Previews
#Preview {
    NavigationStack {
        SkillDetailView(skill: SkillLearning(context: PersistenceController.preview.container.viewContext))
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// Helper extension
extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
