import SwiftUI
import CoreData

import SwiftUI
import CoreData

struct SkillDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skill: SkillLearning
    
    @State private var showingEditView = false
    @State private var showingResourceSheet = false
    @State private var showingColorPicker = false
    @State private var newResource = ""
    @State private var showingUpdateSheet = false
    @State private var todaysUpdate = ""
    
    // Computed properties
    private var updates: [DailyUpdate] {
        skill.sortedDailyUpdates()
    }
    
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
                // Header Section with Color Picker
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(skill.skillName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(skill.skillColor)
                        
                        Text(progressStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingColorPicker = true
                    } label: {
                        Circle()
                            .fill(skill.skillColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .accessibilityLabel("Change skill color")
                }
                
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
                        .tint(skill.skillColor)
                    
                    Slider(value: $skill.progress, in: 0...1, step: 0.01)
                        .tint(skill.skillColor)
                        .onChange(of: skill.progress) { _, _ in
                            saveChanges()
                        }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                
                // Dates Section
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
                
                // Daily Updates Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Daily Updates")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingUpdateSheet = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if updates.isEmpty {
                        ContentUnavailableView(
                            "No Updates Yet",
                            systemImage: "calendar.badge.plus",
                            description: Text("Add your first update to track daily progress")
                        )
                    } else {
                        ForEach(updates) { update in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(update.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Button(action: { removeUpdate(update) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                                
                                Text(update.notes)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
                
                // Resources Section
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
        .sheet(isPresented: $showingColorPicker) {
            NavigationStack {
                SliderColorPicker(color: Binding(
                    get: { skill.skillColor },
                    set: { newValue in
                        skill.skillColor = newValue
                        try? viewContext.save()
                    }
                ))
                .navigationTitle("Choose Color")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingColorPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingResourceSheet) {
            resourceInputSheet
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showingUpdateSheet) {
            dailyUpdateSheet
                .presentationBackground(.clear)
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
    
    private func addDailyUpdate() {
        let trimmedUpdate = todaysUpdate.trimmed
        guard !trimmedUpdate.isEmpty else { return }
        
        viewContext.perform {
            skill.addDailyUpdate(notes: trimmedUpdate)
            todaysUpdate = ""
            saveChanges()
            showingUpdateSheet = false
        }
    }
    
    private func removeUpdate(_ update: DailyUpdate) {
        viewContext.perform {
            skill.removeDailyUpdate(update)
            saveChanges()
        }
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
    
    private var dailyUpdateSheet: some View {
        NavigationStack {
            Form {
                Section("Today's Progress") {
                    TextEditor(text: $todaysUpdate)
                        .frame(minHeight: 100)
                        .autocapitalization(.sentences)
                }
                
                Section {
                    Button("Add Update") {
                        addDailyUpdate()
                    }
                    .disabled(todaysUpdate.trimmed.isEmpty)
                }
            }
            .navigationTitle("Daily Update")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showingUpdateSheet = false
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct EditSkillView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var skill: SkillLearning
    
    @State private var skillName: String
    @State private var startDate: Date
    @State private var targetDate: Date
    @State private var showingColorPicker = false
    
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
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Button {
                            showingColorPicker = true
                        } label: {
                            Circle()
                                .fill(skill.skillColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
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
            .sheet(isPresented: $showingColorPicker) {
                NavigationStack {
                    SliderColorPicker(color: Binding(
                        get: { skill.skillColor },
                        set: { newValue in
                            skill.skillColor = newValue
                            try? viewContext.save()
                        }
                    ))
                    .navigationTitle("Choose Color")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingColorPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
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

struct SliderColorPicker: View {
    @Binding var color: Color
    @State private var red: Double
    @State private var green: Double
    @State private var blue: Double
    
    init(color: Binding<Color>) {
        self._color = color
        let uiColor = UIColor(color.wrappedValue)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        self._red = State(initialValue: Double(r))
        self._green = State(initialValue: Double(g))
        self._blue = State(initialValue: Double(b))
    }
    
    var body: some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 50)
            
            VStack(spacing: 5) {
                customColorSlider(value: $red,
                                gradientColors: [Color(red: 0.5, green: 1, blue: 0.8), Color(red: 1.0, green: 0.98, blue: 0.7)],
                                label: "")
                
                customColorSlider(value: $green,
                                gradientColors: [Color(red: 0.9, green: 0.5, blue: 0.9), Color(red: 0.7, green: 0.98, blue: 0.7)],
                                label: "")
                
                customColorSlider(value: $blue,
                                gradientColors: [Color(red: 0.95, green: 0.95, blue: 0.5), Color(red: 0.7, green: 0.85, blue: 0.98)],
                                label: "")
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .onChange(of: red) { updateColor() }
        .onChange(of: green) { updateColor() }
        .onChange(of: blue) { updateColor() }
    }
    
    private func customColorSlider(value: Binding<Double>, gradientColors: [Color], label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 32)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .position(
                            x: value.wrappedValue * (geometry.size.width - 18) + 18,
                            y: geometry.size.height / 2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = max(0, min(1, gesture.location.x / geometry.size.width))
                                    value.wrappedValue = newValue
                                }
                        )
                }
            }
            .frame(height: 36)
            
            HStack {
                Spacer()
                Text("\(Int(value.wrappedValue * 255))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func updateColor() {
        color = Color(red: red, green: green, blue: blue)
    }
}

#Preview {
    NavigationStack {
        SkillDetailView(skill: {
            let skill = SkillLearning(context: PersistenceController.preview.container.viewContext)
            skill.skillName = "SwiftUI"
            skill.startDate = Date()
            skill.targetDate = Date().addingTimeInterval(60*60*24*30)
            skill.progress = 0.82
            skill.skillColor = .purple
            skill.addDailyUpdate(notes: "Worked on Core Data integration")
            skill.addDailyUpdate(notes: "Practiced animation techniques")
            skill.addResource("SwiftUI Documentation")
            return skill
        }())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
