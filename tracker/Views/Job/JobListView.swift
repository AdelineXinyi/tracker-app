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

// MARK: - Logo Service
class LogoService {
    private let apiKey = "sk_IeNn_0LVQ8Kcx4zM6kLVEw"
    private let cache = NSCache<NSString, UIImage>()
    
    func fetchLogo(for companyName: String) async throws -> UIImage? {
        // Check cache first
        if let cachedImage = cache.object(forKey: companyName as NSString) {
            return cachedImage
        }
        
        // Clean company name for URL
        let cleanedName = companyName
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard !cleanedName.isEmpty else { return nil }
        guard let url = URL(string: "https://api.logo.dev/search?q=\(cleanedName)") else {
            throw LogoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        // Fetch logo data
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse response
        let decoder = JSONDecoder()
        let responses = try decoder.decode([LogoResponse].self, from: data)
        
        // Select the most relevant logo (first one is typically best match)
        guard let bestMatch = responses.first else {
            throw LogoError.noLogoFound
        }
        
        // Get the logo URL
        let imageUrlString = bestMatch.logoUrl
        guard let imageUrl = URL(string: imageUrlString) else {
            throw LogoError.invalidImageURL
        }
        
        // Download image
        let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
        guard let image = UIImage(data: imageData) else {
            throw LogoError.invalidImageData
        }
        
        // Cache the image
        cache.setObject(image, forKey: companyName as NSString)
        return image
    }
    
    enum LogoError: Error {
        case invalidURL
        case noLogoFound
        case invalidImageURL
        case invalidImageData
        case decodingError
    }
}

struct LogoResponse: Decodable {
    let name: String
    let domain: String
    let logoUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case domain
        case logoUrl = "logo_url"
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

private struct RecentApplicationsSection: View {
    var jobs: FetchedResults<JobApplication>
    var deleteAction: (IndexSet) -> Void
    @State private var logoCache: [String: UIImage] = [:]
    @State private var failedLogos: Set<String> = []
    
    var body: some View {
        Section(header: Text("Recent Applications")) {
            if jobs.isEmpty {
                Text("No applications yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(jobs) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        HStack(spacing: 12) {
                            logoView(for: job.companyName)
                            
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
                    .task {
                        if !failedLogos.contains(job.companyName) {
                            await loadLogo(for: job.companyName)
                        }
                    }
                }
                .onDelete(perform: deleteAction)
            }
        }
    }
    
    @ViewBuilder
    private func logoView(for companyName: String) -> some View {
        Group {
            if let logo = logoCache[companyName] {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .cornerRadius(4)
                    
                    Text(companyName.prefix(1).capitalized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 40, height: 40)
    }
    
    private func loadLogo(for companyName: String) async {
        let service = LogoService()
        do {
            if let logo = try await service.fetchLogo(for: companyName) {
                DispatchQueue.main.async {
                    logoCache[companyName] = logo
                }
            }
        } catch {
            print("Logo fetch failed for \(companyName): \(error.localizedDescription)")
            DispatchQueue.main.async {
                failedLogos.insert(companyName)
            }
        }
    }
}

// MARK: - Preview
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
