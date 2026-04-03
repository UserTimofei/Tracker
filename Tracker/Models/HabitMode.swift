//
//  HabitMode.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 22.03.2026.
//
import Foundation

enum HabitMode {
    case create
    case edit(Tracker)
    
    static func == (lhs: HabitMode, rhs: HabitMode) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create):
            return true
        case (.edit(let lhsTracker), .edit(let rhsTracker)):
            return lhsTracker.id == rhsTracker.id
        default:
            return false
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .create:
            return NSLocalizedString("newhabit.create.button", comment: "Create button")
        case .edit:
            return NSLocalizedString("newhabit.save.button", comment: "Save button")
        }
    }
    
    var navigationTitle: String {
        switch self {
        case .create:
            return NSLocalizedString("newhabit.title", comment: "Title for new habit screen")
        case .edit:
            return NSLocalizedString("newhabit.edit.title", comment: "Title for edit habit screen")
        }
    }
}
