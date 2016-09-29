//
//  NSKApiUtils.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

/**
 NearspeakKit API Utils.
*/
struct NSKApiUtils {
    /** Maximal available beacons UUIDS. */
    static let maximalBeaconUUIDs = 20
    
    /** The API base url.
    
    - parameter development: Choose between production and development server.
    - parameter path: The URL path.
    - parameter queryItems: The query items array.
    */
    static func apiURL(_ development: Bool, path: String, queryItems: [URLQueryItem]?) -> URLComponents {
        var baseURL = URLComponents()
        baseURL.scheme = "https"
        
        if development {
            baseURL.scheme = "http"
            baseURL.host = "localhost"
            baseURL.port = 3000
        } else {
            baseURL.host = "api.nearspeak.at"
            //baseURL.port = 443
        }
        
        baseURL.path = "/api/v1/" + path
        
        if let queryItems = queryItems {
            baseURL.queryItems = queryItems
        }
        
        return baseURL
    }
    
    // MARK: Helper methods
    
    /** Helper method to format the hardware id, which is in the most cases the iBeacon UUID, into the correct format. */
    static func formatHardwareId(_ hardwareId: String) -> String {
        return hardwareId.replacingOccurrences(of: "-", with: "", options: .literal, range: nil)
    }
    
    /** Create a correct UUID string from the hardwareId. */
    static func hardwareIdToUUID(_ hardwareId: String) -> UUID? {
        // 36 chars 8-4-4-4-12
        // CEFCC021-E45F-4520-A3AB-9D1EA22873AD
        
        // check if the string is 36 chars long
        if hardwareId.characters.count == 36 {
            return UUID(uuidString: hardwareId)
        }
        
        // if the string lang is 32 the - are missing
        if hardwareId.characters.count == 32 {
            let uuidString = NSMutableString(string: hardwareId)
            
            uuidString.insert("-", at: 8)
            uuidString.insert("-", at: 13)
            uuidString.insert("-", at: 18)
            uuidString.insert("-", at: 23)
            
            return UUID(uuidString: uuidString as String)
        }
        
        return nil
    }
    
}
