//
//  Section.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 22.03.2026.
//
import Foundation

enum Section: Int, CaseIterable {
    case emoji
    case color
    
    var title: String {
        switch self {
        case .emoji: return NSLocalizedString("newhabit.emoji.section", comment: "Emoji section")
        case .color: return NSLocalizedString("newhabit.color.section", comment: "Color section")
        }
    }
}
