//
//  DateParser.swift
//  Nearspeak
//
//  Created by Patrick Steiner on 06.11.14.
//  Copyright (c) 2014 Nearspeak. All rights reserved.
//

import Foundation

/**
 Date parsing extension.
*/
extension Date {
    
    init(dateString: String) {
        let dateStringFormatter = DateFormatter()
        
        // see: http://unicode.org/reports/tr35/tr35-4.html#Date_Format_Patterns
        dateStringFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        let d = dateStringFormatter.date(from: dateString)
        
        (self as NSDate).init(timeInterval: 0, since: d!)
    }
}
