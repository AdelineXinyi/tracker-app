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
                
                Section(header: Text("Recent Applications")) {
                    ForEach(jobs) { job in
                        NavigationLink(destination: JobDetailView(job: job)) {
                            VStack(alignment: .leading) {
                                Text(job.companyName).font(.headline)
                                Text(job.positionName).font(.subheadline)
                                Text(job.applyDate, style: .date)
                            }
                        }
                    }
                    .onDelete(perform: deleteJobs)
                }
            }
            .navigationTitle("Job Applications")
            .toolbar {
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
    
    private func deleteJobs(offsets: IndexSet) {
        withAnimation {
            offsets.map { jobs[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
