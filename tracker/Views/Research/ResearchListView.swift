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
    
    var body: some View {
        NavigationView {
            List {
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
    
    private func deleteResearches(offsets: IndexSet) {
        withAnimation {
            offsets.map { researches[$0] }.forEach(viewContext.delete)
            CoreDataHelper.saveContext()
        }
    }
}
