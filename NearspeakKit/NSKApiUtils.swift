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
    // Nearspeak server urls
    private static let apiPath = "/api/v1/"
  
    /** The URL of the staging server. */
    static let stagingServer = "http://localhost:3000" + apiPath
    
    /** The URL of the production server. */
    static let productionServer = "http://nearspeak.cloudapp.net" + apiPath
}
