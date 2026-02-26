//
//  TrackerStore.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 20.02.2026.
//
import UIKit
import CoreData

final class TrackerStore: Store {
    
    weak var delegate: StoreDelegate?
    
    private enum TrackerEntity {
            static let name = "TrackerCoreData"
            static let trackerId = "trackerId"
            static let nameTracker = "nameTracker"
            static let colorTracker = "colorTracker"
            static let emoji = "emoji"
            static let schedule = "schedule"
            static let category = "category"
        }
        
        private enum CategoryEntity {
            static let title = "title"
            static let trackers = "trackers"
        }
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSManagedObject> = {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
            
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: TrackerEntity.nameTracker, ascending: true)
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
    
    func createTracker(
            id: UUID,
            name: String,
            color: UIColor,
            emoji: String,
            schedule: Set<WeekDay>,
            category: TrackerCategoryCoreData
        ) throws -> Tracker {
            let context = self.context
            let trackerObject = NSEntityDescription.insertNewObject(forEntityName: TrackerEntity.name, into: context)
            
            trackerObject.setValue(id, forKey: TrackerEntity.trackerId)
            trackerObject.setValue(name, forKey: TrackerEntity.nameTracker)
            trackerObject.setValue(color, forKey: TrackerEntity.colorTracker)
            trackerObject.setValue(emoji, forKey: TrackerEntity.emoji)
            print("🔵 Сохраняем расписание напрямую: \(schedule)")
            trackerObject.setValue(schedule, forKey: TrackerEntity.schedule)
            
            trackerObject.setValue(category, forKey: TrackerEntity.category)
            
            try saveContext()
            
            
                return try decodeTracker(from: trackerObject)
        }
    
    private func decodeTracker(from object: NSManagedObject) throws -> Tracker {
            guard let id = object.value(forKey: TrackerEntity.trackerId) as? UUID,
                  let name = object.value(forKey: TrackerEntity.nameTracker) as? String,
                  let color = object.value(forKey: TrackerEntity.colorTracker) as? UIColor,
                  let emoji = object.value(forKey: TrackerEntity.emoji) as? String
            else {
                throw StoreError.decodingError("Не удалось декодировать трекер")
            }
        var schedule: Set<WeekDay> = []
        if let weekdays = object.value(forKey: TrackerEntity.schedule) as? Set<WeekDay> {
            schedule = weekdays
            print("🔵 Прочитано расписание как Set<WeekDay>: \(weekdays)")
        }
        else if let array = object.value(forKey: TrackerEntity.schedule) as? NSArray {
            let weekdays = array.compactMap { $0 as? WeekDay }
            schedule = Set(weekdays)
            print("🔵 Прочитано расписание как NSArray с WeekDay: \(weekdays)")
        }
        else if let scheduleArray = object.value(forKey: TrackerEntity.schedule) as? [Int] {
            schedule = Set(scheduleArray.compactMap { WeekDay(rawValue: $0) })
            print("🔵 Прочитано расписание как [Int]: \(scheduleArray)")
        }
        else if let data = object.value(forKey: TrackerEntity.schedule) as? Data {
            if let scheduleArray = try? JSONDecoder().decode([Int].self, from: data) {
                schedule = Set(scheduleArray.compactMap { WeekDay(rawValue: $0) })
                print("🔵 Прочитано расписание как Data: \(scheduleArray)")
            }
        }
        else if let anyValue = object.value(forKey: TrackerEntity.schedule) {
            print("⚠️ Неизвестный тип schedule: \(type(of: anyValue)) = \(anyValue)")
        }
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
    
    func fetchTracker(by id: UUID) throws -> Tracker? {
        let context = self.context
        let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
        request.predicate = NSPredicate(format: "%K == %@", TrackerEntity.trackerId, id as CVarArg)
        request.fetchLimit = 1
        
        guard let trackerObject = try context.fetch(request).first else {
            return nil
        }
        
        return try decodeTracker(from: trackerObject)
    }
    func fetchAllTrackers() throws -> [Tracker] {
        let context = self.context
        let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
        
        let objects = try context.fetch(request)
        return try objects.compactMap { try decodeTracker(from: $0) }
    }
    
    func updateTracker(
           newTracker: Tracker,
           category: TrackerCategoryCoreData? = nil
       ) throws {
           let context = self.context
           let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
           request.predicate = NSPredicate(format: "%K == %@", TrackerEntity.trackerId, newTracker.id as CVarArg)
           request.fetchLimit = 1
           
           guard let trackerObject = try context.fetch(request).first else {
               throw StoreError.trackerNotFound
           }
           
           trackerObject.setValue(newTracker.name, forKey: TrackerEntity.nameTracker)
           trackerObject.setValue(newTracker.color, forKey: TrackerEntity.colorTracker)
           trackerObject.setValue(newTracker.emoji, forKey: TrackerEntity.emoji)
           trackerObject.setValue(newTracker.schedule, forKey: TrackerEntity.schedule)
           
           if let category = category {
               trackerObject.setValue(category, forKey: TrackerEntity.category)
           }
           
           try saveContext()
       }
    
    func deleteTracker(id: UUID) throws {
            let context = self.context
            let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
            request.predicate = NSPredicate(format: "%K == %@", TrackerEntity.trackerId, id as CVarArg)
            request.fetchLimit = 1
            
            guard let trackerObject = try context.fetch(request).first else {
                throw StoreError.trackerNotFound
            }
            
            context.delete(trackerObject)
            try saveContext()
        }
}

extension TrackerStore:  NSFetchedResultsControllerDelegate {
    
    func setupFetchedResultsController(with predicate: NSPredicate? = nil) throws {
            fetchedResultsController.fetchRequest.predicate = predicate
            try fetchedResultsController.performFetch()
        }
        
        var numberOfSections: Int {
            return fetchedResultsController.sections?.count ?? 0
        }
        
        func numberOfItemsInSection(_ section: Int) -> Int {
            guard let sections = fetchedResultsController.sections, section < sections.count else { return 0 }
            return sections[section].numberOfObjects
        }
    
    func tracker(at indexPath: IndexPath) -> Tracker? {
            guard indexPath.section < numberOfSections,
                  indexPath.item < numberOfItemsInSection(indexPath.section) else {
                print("⚠️ Запрошен несуществующий индекс: section \(indexPath.section), item \(indexPath.item)")
                return nil
            }
            
            let trackerObject = fetchedResultsController.object(at: indexPath)
            return try? decodeTracker(from: trackerObject)
        }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            delegate?.didUpdate()
        }
    
    func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any,
            at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType,
            newIndexPath: IndexPath?
        ) {
            switch type {
            case .insert:
                print("Вставлен объект по пути: \(newIndexPath!)")
            case .delete:
                print("Удален объект по пути: \(indexPath!)")
            case .update:
                print("Обновлен объект по пути: \(indexPath!)")
            case .move:
                print("Объект перемещен с \(indexPath!) на \(newIndexPath!)")
            @unknown default:
                break
            }
        }
}
