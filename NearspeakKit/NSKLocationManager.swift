//
//  NSKLocationManager.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 15.09.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import Foundation
import CoreLocation

public class NSKLocationManager: NSObject {
    
    private let locationManager = CLLocationManager()
    public var currentLocation = CLLocation()
    
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
    
    public func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    public func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension NSKLocationManager: CLLocationManagerDelegate {
    public func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            //println("DBG: currentLocation \(location.coordinate.latitude) - \(location.coordinate.latitude)")
            currentLocation = location
        }
    }
    
    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("ERROR: \(error.localizedDescription)")
    }
}

