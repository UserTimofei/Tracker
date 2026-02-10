//
//  Service.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 14.01.2026.
//
import Foundation

class Service {
    
    func formatterDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: Date())
    }
}

