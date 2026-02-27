//
//  StoreProtocol.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 27.02.2026.
//

import Foundation

protocol TrackerStoreProtocol {
    func fetchAllCategories() throws -> [TrackerCategory]
    func addTracker(_ tracker: Tracker, toCategory categoryTitle: String) throws
    func markTracker(_ trackerId: UUID, asCompleted  date: Date, isCompleted: Bool) throws
}

protocol RecordStoreProtocol {
    func countRecords(for trackerId: UUID) throws -> Int
    func fetchAllRecords() throws -> [TrackerRecord]
    func addRecord(trackerId: UUID, date: Date) throws  
    func removeRecord(trackerId: UUID, date: Date) throws
}
