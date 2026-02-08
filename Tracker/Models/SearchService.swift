//
//  SearchManager.swift
//  Tracker
//
//  Created by Timofei Kirichenko on 01.02.2026.
//
import Foundation
import UIKit

protocol SearchServiceDelegate: AnyObject {
    func didUpdateSearchResults(_ filteredCategories: [TrackerCategory])
}

class SearchService {

    weak var delegate: SearchServiceDelegate?
    private var allCategories: [TrackerCategory] = []

    func updateCategories(_ categories: [TrackerCategory]) {
        self.allCategories = categories
    }
    
    func filterCategories(searchText: String) {
        if searchText.isEmpty {
            delegate?.didUpdateSearchResults(allCategories)
            return
        }
        
        let query = searchText.lowercased()
        var result: [TrackerCategory] = []
        
        for category in allCategories {
            var matchingTrackers: [Tracker] = []
            
            for tracker in category.trackers {
                if tracker.name.lowercased().contains(query) {
                    matchingTrackers.append(tracker)
                }
            }
            
            if !matchingTrackers.isEmpty {
                result.append(TrackerCategory(
                    header: category.header,
                    trackers: matchingTrackers
                ))
            }
        }
        delegate?.didUpdateSearchResults(result)
    }
}
