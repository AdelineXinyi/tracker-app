//
//  SkillListView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData


struct SkillListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SkillLearning.skillName, ascending: true)],
        animation: .default
    ) private var skills: FetchedResults<SkillLearning>
    
    @State private var showingAddView = false
    @State private var searchText = ""
    @State private var skillToColorize: SkillLearning?
    @State private var summaryText = "Tap analyze to generate insights"
    @State private var isLoading = false
    private let llmService = LLMService(apiKey: Config.deepInfraKey)

    var filteredSkills: [SkillLearning] {
        searchText.isEmpty ? Array(skills) : skills.filter {
            $0.skillName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("AI Analysis")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(summaryText)
                            .font(.subheadline)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Button(action: {
                                Task { await generateSummary() }
                            }) {
                                Text("Analyze Progress")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if filteredSkills.isEmpty {
                    EmptyStateView()
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredSkills) { skill in
                        NavigationLink(destination: SkillDetailView(skill: skill)) {
                            SkillRow(skill: skill)
                        }
                        .listRowBackground(skill.skillColor.opacity(0.2))
                        .swipeActions(edge: .leading) {
                            Button {
                                skillToColorize = skill
                            } label: {
                                Label("Color", systemImage: "paintpalette")
                            }
                            .tint(skill.skillColor)
                        }
                    }
                    .onDelete(perform: deleteSkills)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("My Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .deleteDisabled(viewContext.hasChanges)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddView = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add new skill")
                    }
                }
            }
            .sheet(item: $skillToColorize) { skill in
                NavigationStack {
                    Form {
                        ColorPicker("Skill Color", selection: Binding(
                            get: { skill.skillColor },
                            set: { newValue in
                                skill.skillColor = newValue
                                try? viewContext.save()
                            }
                        ))
                        .padding()
                    }
                    .navigationTitle("Change Color")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                skillToColorize = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingAddView) {
                AddSkillView()
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func generateSummary() async {
        isLoading = true
        do {
            let prompt = LLMHelper.prepareSkillsPrompt(for: Array(skills))
            summaryText = try await llmService.generateSummary(for: prompt)
        } catch {
            summaryText = "Analysis failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func deleteSkills(offsets: IndexSet) {
        let itemsToDelete = offsets.map { skills[$0] }
        
        Task {
            await MainActor.run {
                withAnimation {
                    itemsToDelete.forEach { skill in
                        viewContext.delete(skill)
                    }
                }
            }
            
            do {
                try await viewContext.perform {
                    try viewContext.save()
                }
            } catch {
                await MainActor.run {
                    print("Delete error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Subviews (unchanged from original)
private struct SkillRow: View {
    @ObservedObject var skill: SkillLearning
    
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: skill.targetDate).day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(skill.skillName)
                    .font(.headline)
                    .foregroundColor(skill.skillColor)
                
                Spacer()
                
                Text("\(Int(skill.progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressBar(value: skill.progress)
                .frame(height: 8)
                .tint(skill.skillColor)
            
            HStack {
                Text("Started: \(skill.startDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                
                Spacer()
                
                if daysRemaining > 0 {
                    Text("\(daysRemaining) days left")
                        .font(.caption2)
                        .foregroundColor(daysRemaining < 7 ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            Color.clear)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "No Skills Added",
            systemImage: "lightbulb",
            description: Text("Start by adding a skill you want to learn")
        )
        .background(Color(.systemBackground))
    }
}

// MARK: - Previews (unchanged)
#Preview {
    SkillListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
