//
//  NSKApiUtils.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

struct NSKApiUtils {
    // Nearspeak server urls
    private static let apiPath = "/api/v1/"
    
    static let stagingServer = "http://localhost:3000" + apiPath
    static let productionServer = "http://nearspeak.cloudapp.net" + apiPath
}
