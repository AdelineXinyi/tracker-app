//
//  Persistence.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample JobApplication
        let job = JobApplication(context: viewContext)
        job.companyName = "Apple"
        job.positionName = "iOS Developer"
        job.applyDate = Date()
        job.status = "Applied"
        job.requiredSkills = "Swift,UIKit,CoreData"
        
        // Add sample ResearchApplication
        let research = ResearchApplication(context: viewContext)
        research.universityName = "Stanford"
        research.professorName = "Dr. Smith"
        research.researchField = "Computer Science"
        research.applyDate = Date()
        research.status = "Submitted"
        
        // Add sample SkillLearning
        let skill = SkillLearning(context: viewContext)
        skill.skillName = "SwiftUI"
        skill.startDate = Date()
        skill.targetDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        skill.progress = 0.25
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
