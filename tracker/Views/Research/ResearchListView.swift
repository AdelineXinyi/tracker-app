//
//  ResearchListView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//
import SwiftUI
import CoreData


struct ResearchListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ResearchApplication.applyDate, ascending: false)],
        animation: .default)
    private var researches: FetchedResults<ResearchApplication>
    
    @State private var showingAddView = false
    @State private var summaryText = ""
    @State private var isLoading = false
   
    
    private let llmService = LLMService(apiKey: Config.deepInfraKey)

    var body: some View {
        NavigationStack {
            List {
                AnalysisSection(summaryText: $summaryText,
                              isLoading: $isLoading,
                              generateSummary: generateSummary)
                
                ResearchApplicationsSection(researches: researches,
                                          deleteAction: deleteResearches)
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
           
        }
    }
    
    private func deleteResearches(offsets: IndexSet) {
    
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
    
    private let fixedHeight: CGFloat = 120
    
    var body: some View {
        Section(header: Text("AI Analysis")) {
            ZStack {
                // Image background with proper implementation
                Image("bg") // Your image named "bg"
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: fixedHeight)
                    .overlay(Color.white.opacity(0.7)) // White overlay for readability
                    .clipShape(RoundedRectangle(cornerRadius: 10)) // Rounded corners
                
                // Content
                VStack(spacing: 8) {
                    ScrollView(.vertical) {
                        Text(summaryText)
                            .font(.subheadline)
                            .foregroundColor(.black) // Ensure text is readable
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: fixedHeight - 40) // Adjusted height
                    
                    if isLoading {
                        ProgressView()
                            .offset(y: -35) // Adjusted position
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(height: fixedHeight)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isLoading {
                    Task { await generateSummary() }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
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
