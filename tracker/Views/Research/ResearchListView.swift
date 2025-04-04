//
//  ResearchListView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//
import SwiftUI
import CoreData


import SwiftUI
import CoreData

struct ResearchListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ResearchApplication.applyDate, ascending: false)],
        animation: .default)
    private var researches: FetchedResults<ResearchApplication>
    
    @State private var showingAddView = false
    @State private var summaryText = "Tap analyze to generate insights"
    @State private var isLoading = false
    @State private var showingDeleteAlert = false
    @State private var itemsToDelete: IndexSet?
    
    private let llmService = LLMService(apiKey: Config.deepInfraKey)

    var body: some View {
        NavigationStack {
            List {
                AnalysisSection(summaryText: $summaryText,
                              isLoading: $isLoading,
                              generateSummary: generateSummary)
                
                ResearchApplicationsSection(researches: researches,
                                          deleteAction: confirmDelete)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Research")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddView = true }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddResearchView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("Delete Applications",
                   isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive, action: deleteConfirmedResearches)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete these research applications?")
            }
        }
    }
    
    private func confirmDelete(offsets: IndexSet) {
        itemsToDelete = offsets
        showingDeleteAlert = true
    }
    
    private func deleteConfirmedResearches() {
        guard let offsets = itemsToDelete else { return }
        
        withAnimation {
            offsets.map { researches[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete research: \(error.localizedDescription)")
            }
        }
    }
    
    private func generateSummary() async {
        isLoading = true
        do {
            let prompt = LLMHelper.prepareResearchPrompt(for: Array(researches))
            summaryText = try await llmService.generateSummary(for: prompt)
        } catch {
            summaryText = "Analysis failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Subviews

private struct AnalysisSection: View {
    @Binding var summaryText: String
    @Binding var isLoading: Bool
    var generateSummary: () async -> Void
    
    var body: some View {
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
                        Text("Analyze Trends")
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct ResearchApplicationsSection: View {
    var researches: FetchedResults<ResearchApplication>
    var deleteAction: (IndexSet) -> Void
    
    var body: some View {
        Section(header: Text("Research Applications")) {
            if researches.isEmpty {
                Text("No research applications yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(researches) { research in
                    NavigationLink(destination: ResearchDetailView(research: research)) {
                        VStack(alignment: .leading) {
                            Text(research.universityName )
                                .font(.headline)
                            Text(research.professorName )
                                .font(.subheadline)
                            Text(research.researchField )
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteAction)
            }
        }
    }
}

// MARK: - Preview

struct ResearchListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let research = ResearchApplication(context: context)
        research.universityName = "Stanford"
        research.professorName = "Dr. Smith"
        research.researchField = "Computer Science"
        research.applyDate = Date()
        research.status = "Submitted"
        
        return ResearchListView()
            .environment(\.managedObjectContext, context)
    }
}
