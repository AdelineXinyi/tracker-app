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
    
    convenience init(
        uni: String,
        professor: String,
        field: [String],
        status: ResearchStatus,
        context: NSManagedObjectContext
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "JobApplication", in: context)!
        self.init(entity: entity, insertInto: context)
        self.universityName = uni
        self.professorName = professor
        self.applyDate = Date()
        self.researchField = field.joined(separator: ",")
        self.status = status.rawValue
    }
    
    // MARK: - Enums
    public enum ResearchStatus: String, CaseIterable {
        case preparing = "Preparing"
        case submitted = "Submitted"
        case underReview = "Under Review"
        case accepted = "Accepted"
        case rejected = "Rejected"
    }
    
    // MARK: - Computed Properties
    public var id: NSManagedObjectID {
        return self.objectID
    }
    
    
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ResearchApplication> {
        return NSFetchRequest<ResearchApplication>(entityName: "ResearchApplication")
    }
    
    func updateStatus(_ newStatus: ResearchStatus) {
            self.status = newStatus.rawValue
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
