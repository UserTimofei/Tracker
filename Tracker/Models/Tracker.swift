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
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
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
//enum WeekDay: Int, CaseIterable {
//    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
//
//    var title: String {
//        switch self {
//        case .monday: return "Понедельник"
//        case .tuesday: return "Вторник"
//        case .wednesday: return "Среда"
//        case .thursday: return "Четверг"
//        case .friday: return "Пятница"
//        case .saturday: return "Суббота"
//        case .sunday: return "Воскресенье"
//        }
//    }
//}
//
//extension WeekDay {
//    var shortTitle: String {
//        switch self {
//            case .monday: return "Пн"
//            case .tuesday: return "Вт"
//            case .wednesday: return "Ср"
//            case .thursday: return "Чт"
//            case .friday: return "Пт"
//            case .saturday: return "Сб"
//            case .sunday: return "Вс"
//        }
//    }
//}
//
//extension WeekDay {
//    var calendarWeekDay: Int {
//        switch self {
//        case .monday: return 1  // ← Было 2, исправляем на 1
//        case .tuesday: return 2 // ← Было 3, исправляем на 2
//        case .wednesday: return 3
//        case .thursday: return 4
//        case .friday: return 5
//        case .saturday: return 6
//        case .sunday: return 7
//
////        case .monday: return 2
////        case .tuesday: return 3
////        case .wednesday: return 4
////        case .thursday: return 5
////        case .friday: return 6
////        case .saturday: return 7
////        case .sunday: return 1
//        }
//    }
//
//}
//
//
//
