//
//  Item.swift
//  poker
//
//  Created by loffee mac on 2026/6/15.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
