//
//  SkillListView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

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
    
    var filteredSkills: [SkillLearning] {
        searchText.isEmpty ? Array(skills) : skills.filter {
            $0.skillName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredSkills.isEmpty {
                    EmptyStateView()
                } else {
                    ForEach(filteredSkills) { skill in
                        NavigationLink(destination: SkillDetailView(skill: skill)) {
                            SkillRow(skill: skill)
                        }
                    }
                    .onDelete(perform: deleteSkills)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("My Skills")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            showingAddView = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddSkillView()
                    .environment(\.managedObjectContext, viewContext)
                    .presentationBackground(.clear)
            }
        }
    }
    
    private func deleteSkills(offsets: IndexSet) {
        withAnimation {
            offsets.map { skills[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Delete error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Subviews
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
                
                Spacer()
                
                Text("\(Int(skill.progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressBar(value: skill.progress)
                .frame(height: 8)
            
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
    }
}

private struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "No Skills Added",
            systemImage: "lightbulb",
            description: Text("Start by adding a skill you want to learn")
        )
    }
}

// MARK: - Previews
#Preview {
    SkillListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
