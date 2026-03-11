import Foundation

protocol TrackerStoreProtocol {
    func fetchAllCategories() throws -> [TrackerCategory]
    func addTracker(_ tracker: Tracker, toCategory categoryTitle: String) throws
    func markTracker(_ trackerId: UUID, asCompleted  date: Date, isCompleted: Bool) throws
    func togglePin(for trackerId: UUID) throws
    func fetchAllPinnedTrackerIds() throws -> [UUID]
    func deleteTracker(id: UUID) throws
    func updateTracker(newTracker: Tracker, categoryTitle: String?) throws
    func fetchCategoryForTracker(trackerId: UUID) throws -> String?
}

protocol RecordStoreProtocol {
    func countRecords(for trackerId: UUID) throws -> Int
    func fetchAllRecords() throws -> [TrackerRecord]
    func addRecord(trackerId: UUID, date: Date) throws  
    func removeRecord(trackerId: UUID, date: Date) throws
}
