import UIKit
import CoreData

final class UIColorTransformer: ValueTransformer {
    static let name = NSValueTransformerName("UIColorTransformer")
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: color,
                requiringSecureCoding: true
            )
        } catch {
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        let color = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: UIColor.self,
            from: data
        )
        return color
    }
}

final class WeekdayScheduleTransformer: ValueTransformer {
    static let name = NSValueTransformerName("WeekdayScheduleTransformer")
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let weekdays = value as? [WeekDay] {
            return encode(weekdays)
        }
        if let weekdaySet = value as? Set<WeekDay> {
            return encode(Array(weekdaySet))
        }
        return nil
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        let ints = (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        return ints.compactMap { WeekDay(rawValue: $0) }
    }
    
    private func encode(_ weekdays: [WeekDay]) -> Data? {
        let ints = weekdays.map { $0.rawValue }
        return try? JSONEncoder().encode(ints)
    }
}

enum CoreDataTransformers {
    static func register() {
        ValueTransformer.setValueTransformer(
            UIColorTransformer(),
            forName: UIColorTransformer.name
        )
        ValueTransformer.setValueTransformer(
            WeekdayScheduleTransformer(),
            forName: WeekdayScheduleTransformer.name
        )
    }
}
