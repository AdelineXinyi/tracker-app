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
    private let llmService = LLMService(apiKey: Config.deepInfraKey)

    var body: some View {
        NavigationView {
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
                                Text("Analyze Trends")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Research Applications")) {
                    ForEach(researches) { research in
                        NavigationLink(destination: ResearchDetailView(research: research)) {
                            VStack(alignment: .leading) {
                                Text(research.universityName).font(.headline)
                                Text(research.professorName).font(.subheadline)
                                Text(research.researchField)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteResearches)
                }
            }
            .navigationTitle("Research")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddView = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddResearchView()
                    .environment(\.managedObjectContext, viewContext)
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
    
    private func deleteResearches(offsets: IndexSet) {
        withAnimation {
            offsets.map { researches[$0] }.forEach(viewContext.delete)
            CoreDataHelper.saveContext()
        }
    }
}
