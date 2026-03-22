import UIKit
struct Tracker {
    let id: UUID
    let name: String
    let color: UIColor
    let emoji: String
    let schedule: Set<WeekDay>
}


enum WeekDay: Int, CaseIterable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
    
    var title: String {
        switch self {
        case .monday: return NSLocalizedString("monday", comment: "Monday")
        case .tuesday: return NSLocalizedString("tuesday", comment: "Tuesday")
        case .wednesday: return NSLocalizedString("wednesday", comment: "Wednesday")
        case .thursday: return NSLocalizedString("thursday", comment: "Thursday")
        case .friday: return NSLocalizedString("friday", comment: "Friday")
        case .saturday: return NSLocalizedString("saturday", comment: "Saturday")
        case .sunday: return NSLocalizedString("sunday", comment: "Sunday")
        }
    }
    
    var shortTitle: String {
        switch self {
        case .monday: return NSLocalizedString("monday.short", comment: "Mon")
        case .tuesday: return NSLocalizedString("tuesday.short", comment: "Tue")
        case .wednesday: return NSLocalizedString("wednesday.short", comment: "Wed")
        case .thursday: return NSLocalizedString("thursday.short", comment: "Thu")
        case .friday: return NSLocalizedString("friday.short", comment: "Fri")
        case .saturday: return NSLocalizedString("saturday.short", comment: "Sat")
        case .sunday: return NSLocalizedString("sunday.short", comment: "Sun")
        }
    }
    
    var calendarWeekDay: Int {
        switch self {
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        case .sunday: return 1
        }
    }
}
