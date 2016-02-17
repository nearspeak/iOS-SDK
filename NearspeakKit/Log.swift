//
//  Log.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 17.02.16.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import Foundation

struct Log {
    private static let Tag = "[NearspeakKit]"
    
    private enum Level : String {
        case Debug = "[DEBUG]"
        case Error = "[ERROR]"
    }
    
    private static func log(level: Level, @autoclosure _ message: () -> String, _ error: NSError? = nil) {
        if let error = error {
            NSLog("%@%@ %@ with error %@", Tag, level.rawValue, message(), error)
        } else {
            NSLog("%@%@ %@", Tag, level.rawValue, message())
        }
    }
    
    static func debug(@autoclosure message: () -> String, _ error: NSError? = nil) {
        #if DEBUG
            log(.Debug, message, error)
        #endif
    }
    
    static func error(@autoclosure message: () -> String, _ error: NSError? = nil) {
        log(.Error, message, error)
    }
}