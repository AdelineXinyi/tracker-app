//
//  SkillLearning.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import Foundation
import CoreData

@objc(SkillLearning)
public class SkillLearning: NSManagedObject, Identifiable {
    
    // MARK: - Core Data Properties
    @NSManaged public var skillName: String
    @NSManaged public var startDate: Date
    @NSManaged public var targetDate: Date
    @NSManaged public var progress: Float
    @NSManaged @objc dynamic public var resources: String?  // Added @objc dynamic for proper KVO
    
    // MARK: - Computed Properties
    public var id: UUID {
        return UUID()
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
    
    var formattedProgress: String {
        "\(Int(progress * 100))%"
    }
    
    var resourceLinks: [String] {
        resources?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []
    }
    
    // MARK: - KVO Compliance
    @objc class func keyPathsForValuesAffectingResources() -> Set<String> {
        return []
    }
    
    // MARK: - Resource Management
    @objc func addResource(_ resource: String) {
        guard !resource.isEmpty else { return }
        
        self.willChangeValue(for: \.resources)
        var current = resourceLinks
        current.append(resource)
        self.resources = current.joined(separator: "\n")
        self.didChangeValue(for: \.resources)
    }
    
    @objc func removeResource(_ resource: String) {
        self.willChangeValue(for: \.resources)
        var current = resourceLinks
        current.removeAll { $0 == resource }
        self.resources = current.joined(separator: "\n")
        self.didChangeValue(for: \.resources)
    }
    
    @objc func setResourcesArray(_ resources: [String]) {
        self.willChangeValue(for: \.resources)
        self.resources = resources.joined(separator: "\n")
        self.didChangeValue(for: \.resources)
    }
    
    // MARK: - Fetch Requests
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SkillLearning> {
        return NSFetchRequest<SkillLearning>(entityName: "SkillLearning")
    }
    
    // MARK: - CRUD Operations
    static func create(
        name: String,
        start: Date = Date(),
        target: Date,
        progress: Float = 0,
        resources: [String] = [],
        in context: NSManagedObjectContext
    ) -> SkillLearning {
        let newSkill = SkillLearning(context: context)
        newSkill.skillName = name
        newSkill.startDate = start
        newSkill.targetDate = target
        newSkill.progress = progress
        newSkill.setResourcesArray(resources)  // Use the safe setter
        return newSkill
    }
    
    static func activeSkills(in context: NSManagedObjectContext) -> [SkillLearning] {
        let request: NSFetchRequest<SkillLearning> = fetchRequest()
        request.predicate = NSPredicate(format: "progress < 1.0")
        request.sortDescriptors = [
            NSSortDescriptor(key: "targetDate", ascending: true),
            NSSortDescriptor(key: "skillName", ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active skills: \(error)")
            return []
        }
    }
    
    // MARK: - Save Validation
    public override func willSave() {
        super.willSave()
        
        // Clean up empty resources
        if resources?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false {
            resources = nil
        }
    }
}
