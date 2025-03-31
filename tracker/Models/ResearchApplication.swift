//
//  ResearchApplication.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import Foundation
import CoreData

@objc(ResearchApplication)
public class ResearchApplication: NSManagedObject, Identifiable {
    // MARK: - Core Data Properties
    @NSManaged public var universityName: String
    @NSManaged public var professorName: String
    @NSManaged public var researchField: String
    @NSManaged public var applyDate: Date
    @NSManaged public var status: String
    
    // MARK: - Enums
    public enum ResearchStatus: String, CaseIterable {
        case preparing = "Preparing"
        case submitted = "Submitted"
        case underReview = "Under Review"
        case accepted = "Accepted"
        case rejected = "Rejected"
    }
    
    // MARK: - Computed Properties
    public var id: UUID {
        return UUID()
    }
    
    var formattedApplyDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: applyDate)
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ResearchApplication> {
        return NSFetchRequest<ResearchApplication>(entityName: "ResearchApplication")
    }
    
    // MARK: - CRUD Operations
    static func create(
        university: String,
        professor: String,
        field: String,
        status: ResearchStatus,
        in context: NSManagedObjectContext
    ) -> ResearchApplication {
        let newResearch = ResearchApplication(context: context)
        newResearch.universityName = university
        newResearch.professorName = professor
        newResearch.researchField = field
        newResearch.applyDate = Date()
        newResearch.status = status.rawValue
        return newResearch
    }
    
    static func recentApplications(in context: NSManagedObjectContext, limit: Int = 5) -> [ResearchApplication] {
        let request: NSFetchRequest<ResearchApplication> = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "applyDate", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent research apps: \(error)")
            return []
        }
    }
}
