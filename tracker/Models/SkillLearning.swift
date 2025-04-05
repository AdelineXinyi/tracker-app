//
//  SkillLearning.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import Foundation
import CoreData
import UIKit
import SwiftUI

@objc(SkillLearning)
public class SkillLearning: NSManagedObject, Identifiable {
    
    // MARK: - Core Data Properties
    @NSManaged public var skillName: String
    @NSManaged public var startDate: Date
    @NSManaged public var targetDate: Date
    @NSManaged public var progress: Float
    @NSManaged public var resources: String?
    @NSManaged public var colorData: Data?
    @NSManaged public var dailyUpdates: NSObject? // Transformable for DailyUpdate array
    @NSManaged public var lastUpdateDate: Date?
    
    // MARK: - Color Management
    public var skillColor: Color {
        get {
            if let colorData = self.colorData,
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
            return .blue // Default color
        }
        set {
            let uiColor = UIColor(newValue)
            self.colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        }
    }
    
    public func assignRandomColor() {
        let colors: [Color] = [.red, .green, .blue, .orange, .purple, .pink, .teal, .mint, .indigo]
        self.skillColor = colors.randomElement() ?? .blue
    }
    
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
    
    var wrappedDailyUpdates: [DailyUpdate] {
        get {
            (dailyUpdates as? [DailyUpdate]) ?? []
        }
        set {
            dailyUpdates = newValue as NSObject
        }
    }
    
    // MARK: - Daily Update Management
    func addDailyUpdate(notes: String) {
        var currentUpdates = wrappedDailyUpdates
        let newUpdate = DailyUpdate(date: Date(), notes: notes)
        currentUpdates.append(newUpdate)
        wrappedDailyUpdates = currentUpdates
        lastUpdateDate = Date()
    }
    
    func removeDailyUpdate(_ update: DailyUpdate) {
        var currentUpdates = wrappedDailyUpdates
        currentUpdates.removeAll { $0.id == update.id }
        wrappedDailyUpdates = currentUpdates
    }
    
    func sortedDailyUpdates() -> [DailyUpdate] {
        wrappedDailyUpdates.sorted { $0.date > $1.date }
    }
    
    // MARK: - Resource Management
    func addResource(_ resource: String) {
        guard !resource.isEmpty else { return }
        
        var current = resourceLinks
        current.append(resource)
        self.resources = current.joined(separator: "\n")
    }
    
    func removeResource(_ resource: String) {
        var current = resourceLinks
        current.removeAll { $0 == resource }
        self.resources = current.joined(separator: "\n")
    }
    
    func setResourcesArray(_ resources: [String]) {
        self.resources = resources.joined(separator: "\n")
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
        color: Color? = nil,
        in context: NSManagedObjectContext
    ) -> SkillLearning {
        let newSkill = SkillLearning(context: context)
        newSkill.skillName = name
        newSkill.startDate = start
        newSkill.targetDate = target
        newSkill.progress = progress
        newSkill.setResourcesArray(resources)
        newSkill.skillColor = color ?? Color.blue
        newSkill.dailyUpdates = [] as NSObject
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
            let results = try context.fetch(request)
            // Ensure all skills have a color and empty updates array
            results.forEach { skill in
                if skill.colorData == nil {
                    skill.assignRandomColor()
                }
                if skill.dailyUpdates == nil {
                    skill.dailyUpdates = [] as NSObject
                }
            }
            return results
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
        
        // Ensure color data is set
        if colorData == nil {
            assignRandomColor()
        }
        
        // Ensure dailyUpdates is never nil
        if dailyUpdates == nil {
            dailyUpdates = [] as NSObject
        }
    }
}

// MARK: - DailyUpdate Model
struct DailyUpdate: Identifiable, Codable {
    let id: UUID
    let date: Date
    let notes: String
    
    init(date: Date, notes: String) {
        self.id = UUID()
        self.date = date
        self.notes = notes
    }
}
