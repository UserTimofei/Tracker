
import Foundation

struct TrackerRecord: Hashable {
//    let id: UUID
    let trackerId: UUID
    let date: Date
    
//    static func == (lhs: TrackerRecord, rhs: TrackerRecord) -> Bool {
//            return lhs.trackerId == rhs.trackerId &&
//                   Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
//        }
//    func hash(into hasher: inout Hasher) {
//            hasher.combine(trackerId)
//            hasher.combine(Calendar.current.startOfDay(for: date))
//        }
    
}

