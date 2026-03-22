import UIKit
import CoreData

final class TrackerCategoryStore: Store {
    
    weak var delegate: StoreDelegate?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true),
        ]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        
        return controller
    }()
    
    func setupFetchedResultsController(with predicate: NSPredicate? = nil) throws {
        fetchedResultsController.fetchRequest.predicate = predicate
        try fetchedResultsController.performFetch()
    }
    
    var numberOfCategories: Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func category(at index: Int) -> TrackerCategory? {
        guard let categoryEntity = fetchedResultsController.fetchedObjects?[index] else {
            return nil
        }
        return try? decodeCategory(from: categoryEntity)
    }
    
    func createCategory(title: String) throws -> TrackerCategory {
        
        let fetchRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title ==[c] %@", title)
        
        let existingCategories = try context.fetch(fetchRequest)
        if !existingCategories.isEmpty {
            throw StoreError.categoryAlreadyExists
        }
        
        let categoryEntity = TrackerCategoryCoreData(context: context)
        
        categoryEntity.idCategory = UUID()
            print("📝 Создана категория '\(title)' с ID: \(categoryEntity.idCategory?.uuidString ?? "nil")")
            categoryEntity.title = title
        
        try saveContext()
        
        return try decodeCategory(from: categoryEntity)
    }
    
    func updateCategory(oldTitle: String, newTitle: String) throws {
        let predicate = NSPredicate(format: "title == %@", oldTitle)
        let categories = try fetchEntities(TrackerCategoryCoreData.self, predicate: predicate)
        guard let categoryEntity = categories.first else {
            throw StoreError.categoryNotFound
        }
        categoryEntity.title = newTitle
        try saveContext()
    }
    
    func deleteCategory(title: String) throws {
        let predicate = NSPredicate(format: "title == %@", title)
        let categories = try fetchEntities(TrackerCategoryCoreData.self, predicate: predicate)
        guard let categoryEntity = categories.first else {
            throw StoreError.categoryNotFound
        }
        
        context.delete(categoryEntity)
        try saveContext()
    }
    
    func fetchCategoryCoreData(by title: String) throws -> TrackerCategoryCoreData? {
        let predicate = NSPredicate(format: "title == %@", title)
        let categories = try fetchEntities(TrackerCategoryCoreData.self, predicate: predicate)
        
        if let category = categories.first {
            print("🔍 Найдена категория '\(title)' с ID: \(category.idCategory?.uuidString ?? "nil")")
        } else {
            print("🔍 Категория '\(title)' не найдена")
        }
        
        return categories.first
    }
    
    private func decodeCategory(from entity: TrackerCategoryCoreData) throws -> TrackerCategory {
        guard let title = entity.title else {
            throw StoreError.decodingError("Не удалось декодировать категорию")
        }
        var trackers: [Tracker] = []
        
        if let trackersSet = entity.trackers as? Set<TrackerCoreData> {
            print("  🔗 В категории '\(title)' найдено трекеров в отношении: \(trackersSet.count)")
            
            let trackerStore = TrackerStore(context: context, categoryStore: self)
            
            for trackerEntity in trackersSet {
                if let trackerId = trackerEntity.trackerId {
                    print("    🔍 Загружаем трекер с ID: \(trackerId)")
                    if let tracker = try? trackerStore.fetchTracker(by: trackerId) {
                        trackers.append(tracker)
                        print("    ✅ Трекер загружен: \(tracker.name)")
                    } else {
                        print("    ❌ Не удалось загрузить трекер с ID: \(trackerId)")
                    }
                }
            }
            trackers.sort { $0.id.uuidString < $1.id.uuidString }
        } else {
            print("  ⚠️ В категории '\(title)' нет трекеров в отношении")
        }

        return TrackerCategory(header: title, trackers: trackers)
    }
    func fetchAllCategories() throws -> [TrackerCategory] {
        let categoryEntities = try fetchEntities(TrackerCategoryCoreData.self)
        
        return try categoryEntities.map { entity in
            let category = try decodeCategory(from: entity)

            return category
        }
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        delegate?.didUpdate()
    }
}
