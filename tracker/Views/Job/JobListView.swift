//
//  JobListView.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import SwiftUI
import CoreData

struct JobListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JobApplication.applyDate, ascending: false)],
        animation: .default)
    private var jobs: FetchedResults<JobApplication>
    
    @State private var showingAddView = false
    @State private var summaryText = "Tap analyze to generate insights"
    @State private var isLoading = false
    
    private let llmService = LLMService(apiKey: Config.deepInfraKey)
    
    var body: some View {
        NavigationStack {
            List {
                AnalysisSection(summaryText: $summaryText,
                             isLoading: $isLoading,
                             generateSummary: generateSummary)
                
                RecentApplicationsSection(jobs: jobs,
                                       deleteAction: deleteJobs)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Job Applications")
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
                AddJobView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func deleteJobs(offsets: IndexSet) {
        withAnimation {
            offsets.map { jobs[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete jobs: \(error.localizedDescription)")
            }
        }
    }
    
    private func generateSummary() async {
        isLoading = true
        do {
            let prompt = LLMHelper.prepareJobPrompt(for: Array(jobs))
            summaryText = try await llmService.generateSummary(for: prompt)
        } catch {
            summaryText = "Analysis failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Subviews (unchanged)
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

private struct RecentApplicationsSection: View {
    var jobs: FetchedResults<JobApplication>
    var deleteAction: (IndexSet) -> Void
    
    var body: some View {
        Section(header: Text("Recent Applications")) {
            if jobs.isEmpty {
                Text("No applications yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(jobs) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        VStack(alignment: .leading) {
                            Text(job.companyName)
                                .font(.headline)
                            Text(job.positionName)
                                .font(.subheadline)
                            Text(job.applyDate.formatted(date: .abbreviated, time: .omitted))
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

// MARK: - Preview (unchanged)
struct JobListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let job = JobApplication(context: context)
        job.companyName = "Apple"
        job.positionName = "iOS Developer"
        job.applyDate = Date()
        job.status = "Applied"
        job.requiredSkills = "Swift,UIKit,CoreData"
        
        return JobListView()
            .environment(\.managedObjectContext, context)
    }
}
