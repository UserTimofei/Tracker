import UIKit
import CoreData

final class AppDependencies {
    static let shared = AppDependencies()
    
    private let context: NSManagedObjectContext
    
    private init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate не найден")
        }
        self.context = appDelegate.persistentContainer.viewContext
    }
    
    func makeTrackerStore() -> TrackerStoreProtocol {
        let context = self.context
        let categoryStore = TrackerCategoryStore(context: context)
        let trackerStore = TrackerStore(context: context, categoryStore: categoryStore)
        let recordStore = TrackerRecordStore(context: context)
        return TrackerStoreFacade(
            trackerStore: trackerStore,
            categoryStore: categoryStore,
            recordStore: recordStore
        )
    }
    
    func makeRecordStore() -> RecordStoreProtocol {
        return TrackerRecordStore(context: context)
    }
}
