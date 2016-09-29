//
//  NSKLocationManager.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 15.09.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import Foundation
import CoreLocation

open class NSKLocationManager: NSObject {
    
    fileprivate let locationManager = CLLocationManager()
    open var currentLocation = CLLocation()
    
    /**
    Initializer for this class.
    */
    public override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        
        startLocationUpdates()
    }
    
    open func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    open func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension NSKLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation! {
            currentLocation = location
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.error("\(#function)", error)
    }
}

