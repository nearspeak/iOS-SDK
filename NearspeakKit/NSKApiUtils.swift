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
    /** The API base url.
    
    :param: development Choose between production and development server.
    :param: path The URL path.
    :param: queryItems The query items array.
    */
    static func apiURL(development: Bool, path: String, queryItems: [NSURLQueryItem]?) -> NSURLComponents {
        var baseURL = NSURLComponents()
        baseURL.scheme = "http"
        
        if development {
            baseURL.host = "localhost"
            baseURL.port = 3000
        } else {
            baseURL.host = "nearspeak.cloudapp.net"
        }
        
        baseURL.path = "/api/v1/" + path
        
        if let queryItems = queryItems {
            baseURL.queryItems = queryItems
        }
        
        return baseURL
    }
}
