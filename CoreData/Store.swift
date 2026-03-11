import UIKit
import CoreData

protocol StoreDelegate: AnyObject {
    func didUpdate()
}

class Store: NSObject {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience override init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {
            fatalError("Не удалось получить AppDelegate")
        }
        self.init(context: appDelegate.persistentContainer.viewContext)
    }
    
    func fetchEntities<T: NSManagedObject>(
        _ entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entityType))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            throw StoreError.fetchFailed(error.localizedDescription)
        }
    }
    
    func saveContext() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw StoreError.failedToSave(error.localizedDescription)
        }
    }
    
}

enum StoreError: Error {
    case noAppDelegate
    case failedToSave(String)
    case fetchFailed(String)
    case decodingError(String)
    case trackerNotFound
    case categoryNotFound
    case recordNotFound
    case categoryAlreadyExists 
}
