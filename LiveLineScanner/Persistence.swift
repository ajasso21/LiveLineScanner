//
//  Persistence.swift
//  LiveLineScanner
//
//  Created by Aaron Jasso on 5/22/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample sports
        let sports = ["NFL", "NBA", "MLB", "NHL"]
        for sportName in sports {
            let sport = Sport(context: viewContext)
            sport.id = UUID()
            sport.name = sportName
            
            // Create some teams for each sport
            for _ in 1...3 {
                let team = Team(context: viewContext)
                team.id = UUID()
                team.name = "Team \(UUID().uuidString.prefix(4))"
                team.sport = sport
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Preview provider error: \(error.localizedDescription)")
        }
        return result
    }()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LiveLineScanner")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        // Configure view context
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Utility Functions

    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
                context.rollback()
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        save()
    }
    
    func createBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
