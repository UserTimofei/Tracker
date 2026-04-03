
import XCTest
@testable import Tracker
import SnapshotTesting

final class TrackerTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    // MARK: - Светлая тема
    func testTrackersViewControllerLightThemeSnapshot() throws {
        let mockStore = MockTrackerStore()
        let mockRecordStore = MockRecordStore()
        
        let controller = TrackersViewController(store: mockStore, recordStore: mockRecordStore)
        let navigationController = UINavigationController(rootViewController: controller)
        
        _ = controller.view
        _ = navigationController.view
        
        assertSnapshot(
            matching: navigationController,
            as: .image(traits: .init(userInterfaceStyle: .light)),
            named: "light_theme"
        )
    }
    
    // MARK: - Темная тема
    func testTrackersViewControllerDarkThemeSnapshot() throws {
        let mockStore = MockTrackerStore()
        let mockRecordStore = MockRecordStore()
        
        let controller = TrackersViewController(store: mockStore, recordStore: mockRecordStore)
        let navigationController = UINavigationController(rootViewController: controller)
        
        _ = controller.view
        _ = navigationController.view
        
        assertSnapshot(
            matching: navigationController,
            as: .image(traits: .init(userInterfaceStyle: .dark)),
            named: "dark_theme"
        )
    }
}

// MARK: - Моки
class MockTrackerStore: TrackerStoreProtocol {
    var testCategories: [TrackerCategory] = [
        TrackerCategory(header: "Категория 1", trackers: [
            Tracker(id: UUID(), name: "Трекер 1", color: .systemBlue, emoji: "😀", schedule: [.monday])
        ]),
        TrackerCategory(header: "Категория 2", trackers: [
            Tracker(id: UUID(), name: "Трекер 2", color: .systemRed, emoji: "😎", schedule: [.tuesday])
        ])
    ]
    
    func fetchAllCategories() throws -> [TrackerCategory] { return testCategories }
    func addTracker(_ tracker: Tracker, toCategory categoryTitle: String) throws {}
    func markTracker(_ trackerId: UUID, asCompleted date: Date, isCompleted: Bool) throws {}
    func togglePin(for trackerId: UUID) throws {}
    func fetchAllPinnedTrackerIds() throws -> [UUID] { return [] }
    func deleteTracker(id: UUID) throws {}
    func updateTracker(newTracker: Tracker, categoryTitle: String?) throws {}
    func fetchCategoryForTracker(trackerId: UUID) throws -> String? { return "" }
}

class MockRecordStore: RecordStoreProtocol {
    func countRecords(for trackerId: UUID) throws -> Int { return 0 }
    func fetchAllRecords() throws -> [TrackerRecord] { return [] }
    func addRecord(trackerId: UUID, date: Date) throws {}
    func removeRecord(trackerId: UUID, date: Date) throws {}
}
