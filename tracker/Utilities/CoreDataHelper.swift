//
//  CoreDataHelper.swift
//  tracker
//
//  Created by xinyi li on 3/30/25.
//

import CoreData

struct CoreDataHelper {
    static let context = PersistenceController.shared.container.viewContext
    
    static func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    static func batchDelete(entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("Error batch deleting: \(error)")
        }
    }
    
    static func createSampleData() {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample job applications
        for i in 1...5 {
            let job = JobApplication(context: context)
            job.companyName = ["Apple", "Google", "Amazon", "Microsoft", "Tesla"][i-1]
            job.positionName = ["iOS Developer", "SWE", "Data Scientist", "PM", "ML Engineer"][i-1]
            job.applyDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            job.status = ["Applied", "Interview", "Offer", "Rejected", "Applied"][i-1]
        }
        
        saveContext()
    }
}
