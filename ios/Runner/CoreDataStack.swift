import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "ManWen")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("CoreData load error: \(error)") }
        }
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges { try? context.save() }
    }
}
