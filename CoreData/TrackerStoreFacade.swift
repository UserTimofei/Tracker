//
//  TrackerStoreFacade.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 27.02.2026.
//

import Foundation

final class TrackerStoreFacade: TrackerStoreProtocol {
    private let trackerStore: TrackerStore
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    
    init(trackerStore: TrackerStore, categoryStore: TrackerCategoryStore, recordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.categoryStore = categoryStore
        self.recordStore = recordStore
    }
    
    func fetchAllCategories() throws -> [TrackerCategory] {
        return try categoryStore.fetchAllCategories()
    }
    
    func addTracker(_ tracker: Tracker, toCategory categoryTitle: String) throws {
        let categoryEntity: TrackerCategoryCoreData
        if let existing = try categoryStore.fetchCategoryCoreData(by: categoryTitle) {
            categoryEntity = existing
        } else {
            _ = try categoryStore.createCategory(title: categoryTitle)
            guard let newCategory = try categoryStore.fetchCategoryCoreData(by: categoryTitle) else {
                throw StoreError.categoryNotFound
            }
            categoryEntity = newCategory
        }
        let trackerEntity = TrackerCoreData(context: trackerStore.context)
        trackerEntity.trackerId = tracker.id
        trackerEntity.nameTracker = tracker.name
        trackerEntity.colorTracker = tracker.color
        trackerEntity.emoji = tracker.emoji
        trackerEntity.setValue(tracker.schedule, forKey: "schedule")
        trackerEntity.category = categoryEntity
        
        try trackerStore.saveContext()
    }
    
    func markTracker(_ trackerId: UUID, asCompleted date: Date, isCompleted: Bool) throws {
        if isCompleted {
            try recordStore.addRecord(trackerId: trackerId, date: date)
        } else {
            try recordStore.removeRecord(trackerId: trackerId, date: date)
        }
    }
    
    
}

