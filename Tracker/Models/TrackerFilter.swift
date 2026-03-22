import Foundation

enum TrackerFilter: Int, CaseIterable {
    case all = 0
    case today = 1
    case completed = 2
    case uncompleted = 3
    
    var title: String {
        switch self {
        case .all: return NSLocalizedString("filter.all", comment: "All trackers")
        case .today: return NSLocalizedString("filter.today", comment: "Trackers for today")
        case .completed: return NSLocalizedString("filter.completed", comment: "Completed")
        case .uncompleted: return NSLocalizedString("filter.uncompleted", comment: "Not completed")
        }
    }

    var shouldShowCheckmark: Bool {
        return self == .completed || self == .uncompleted
    }

    var isStrictFilter: Bool {
        return shouldShowCheckmark
    }
}
