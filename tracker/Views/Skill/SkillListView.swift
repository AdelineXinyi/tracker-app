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
        animation: .default)
    private var skills: FetchedResults<SkillLearning>
    
    @State private var showingAddView = false
    @State private var searchText = ""
    
    var filteredSkills: [SkillLearning] {
        if searchText.isEmpty {
            return Array(skills)
        } else {
            return skills.filter {
                $0.skillName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
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
                    AddButton(action: { showingAddView = true })
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddSkillView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func deleteSkills(offsets: IndexSet) {
        withAnimation {
            offsets.map { skills[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Subviews

private struct SkillRow: View {
    @ObservedObject var skill: SkillLearning
    
    var daysRemaining: Int {
        guard let targetDate = skill.targetDate else { return 0 }
        return Calendar.current.dateComponents([.day],
                                             from: Date(),
                                             to: targetDate).day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(skill.skillName ?? "Unknown Skill")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(skill.progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressBar(value: skill.progress)
                .frame(height: 8)
            
            HStack {
                Text("Started: \(skill.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")")
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
        VStack(spacing: 16) {
            Image(systemName: "lightbulb")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            Text("No Skills Added Yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Start by adding a skill you want to learn")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

struct SkillListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Clear existing data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SkillLearning.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? context.execute(deleteRequest)
        
        // Add sample skills
        let skill1 = SkillLearning(context: context)
        skill1.skillName = "SwiftUI"
        skill1.startDate = Date()
        skill1.targetDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        skill1.progress = 0.65
        
        let skill2 = SkillLearning(context: context)
        skill2.skillName = "Machine Learning"
        skill2.startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        skill2.targetDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())
        skill2.progress = 0.25
        
        return SkillListView()
            .environment(\.managedObjectContext, context)
    }
}
