//
//  JobApplication.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//


import Foundation
import CoreData

@objc(JobApplication)
public class JobApplication: NSManagedObject, Identifiable {
    
    // MARK: - Core Data Properties
    @NSManaged public var companyName: String
    @NSManaged public var positionName: String
    @NSManaged public var applyDate: Date
    @NSManaged public var requiredSkills: String?
    @NSManaged public var status: String
    
    // MARK: - Initialization
    convenience init(
        company: String,
        position: String,
        skills: [String],
        status: ApplicationStatus,
        context: NSManagedObjectContext
    ) {
        let entity = NSEntityDescription.entity(forEntityName: "JobApplication", in: context)!
        self.init(entity: entity, insertInto: context)
        self.companyName = company
        self.positionName = position
        self.applyDate = Date()
        self.requiredSkills = skills.joined(separator: ",")
        self.status = status.rawValue
    }
    
    // MARK: - Enums
    public enum ApplicationStatus: String, CaseIterable {
        case applied = "Applied"
        case interview = "Interview"
        case offer = "Offer"
        case rejected = "Rejected"
    }
    
    // MARK: - Computed Properties
    public var id: NSManagedObjectID {
        return self.objectID
    }
    
    var skillsArray: [String] {
        requiredSkills?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobApplication> {
        return NSFetchRequest<JobApplication>(entityName: "JobApplication")
    }
    
    // MARK: - Static Methods
    static func countByStatus(in context: NSManagedObjectContext) -> [String: Int] {
        let request: NSFetchRequest<JobApplication> = fetchRequest()
        do {
            let apps = try context.fetch(request)
            var counts: [String: Int] = [:]
            ApplicationStatus.allCases.forEach { status in
                counts[status.rawValue] = apps.filter { $0.status == status.rawValue }.count
            }
            return counts
        } catch {
            print("Error fetching job applications: \(error)")
            return [:]
        }
    }
    
    // MARK: - Instance Methods
    func updateStatus(_ newStatus: ApplicationStatus) {
        self.status = newStatus.rawValue
    }
    
    func addSkills(_ newSkills: [String]) {
        var currentSkills = skillsArray
        currentSkills.append(contentsOf: newSkills)
        requiredSkills = currentSkills.joined(separator: ",")
    }
}
