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
extension NSDate {
    convenience
    init(dateString: String) {
        let dateStringFormatter = NSDateFormatter()
        
        // see: http://unicode.org/reports/tr35/tr35-4.html#Date_Format_Patterns
        dateStringFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        let d = dateStringFormatter.dateFromString(dateString)
        
        self.init(timeInterval: 0, sinceDate: d!)
    }
}
