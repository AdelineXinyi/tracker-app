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
    
    var body: some View {
        NavigationView {
            List {
//                Section(header: Text("Statistics")) {
//                    JobStatsView()
//                }
                
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

//struct JobStatsView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    
//    var body: some View {
//        let stats = JobApplication.countByStatus(in: viewContext)
//        
//        HStack {
//            StatsCard(value: "\(stats.values.reduce(0, +))", label: "Total", systemImage: "briefcase")
//            StatsCard(value: "\(stats["Applied"] ?? 0)", label: "Applied", systemImage: "envelope")
//            StatsCard(value: "\(stats["Interview"] ?? 0)", label: "Interview", systemImage: "person.2")
//        }
//    }
//}
