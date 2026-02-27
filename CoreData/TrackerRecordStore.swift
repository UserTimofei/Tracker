//
//  TrackerRecordStore.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 20.02.2026.
//
import UIKit
import CoreData

final class TrackerRecordStore: Store{
    weak var delegate: StoreDelegate?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let fetchRequest = TrackerRecordCoreData.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "trackerId", ascending: true)
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
    
    func addRecord(trackerId: UUID, date: Date) throws {
 
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
  
        let predicate = NSPredicate(
            format: "trackerId == %@ AND date >= %@ AND date < %@",
            trackerId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
    
        let existingRecords = try fetchEntities(TrackerRecordCoreData.self, predicate: predicate)
    
        if !existingRecords.isEmpty {
            print("📝 Запись уже существует, выходим")
            return
        }
        let recordEntity = TrackerRecordCoreData(context: context)
        recordEntity.trackerId = trackerId
        recordEntity.date = startOfDay
   
        try saveContext()
    
    }
    
    func removeRecord(trackerId: UUID, date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = NSPredicate(
            format: "trackerId == %@ AND date >= %@ AND date < %@",
            trackerId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        let records = try fetchEntities(TrackerRecordCoreData.self, predicate: predicate)
        
        for record in records {
            context.delete(record)
        }
        
        try saveContext()
        }
    
    func countRecords(for trackerId: UUID) throws -> Int {
        let predicate = NSPredicate(format: "trackerId == %@", trackerId as CVarArg)
            let request = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
            request.predicate = predicate
            
            do {
                let count = try context.count(for: request)

                return count
            } catch {
                print("❌ Ошибка подсчета записей: \(error)")
                throw error
            }
        }
        
    func fetchAllRecords() throws -> [TrackerRecord] {
        let recordEntities = try fetchEntities(TrackerRecordCoreData.self)
        
        let records = try recordEntities.compactMap { entity -> TrackerRecord? in
            guard let trackerId = entity.trackerId,
                  let date = entity.date else {
                return nil
            }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
        
        return records
    }
    
}
extension TrackerRecordStore: NSFetchedResultsControllerDelegate, RecordStoreProtocol {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdate()
    }
}
