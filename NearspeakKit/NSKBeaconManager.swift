//
//  NSKBeaconManager.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 16.12.14.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

/*
 * Ranging infos:
 * http://stackoverflow.com/questions/19246493/locationmanagerdidenterregion-not-called-when-a-beacon-is-detected
 */

import UIKit
import CoreLocation

public protocol NSKBeaconManagerDelegate {
    func beaconManager(manager: NSKBeaconManager!, foundBeacons:[CLBeacon])
}

public class NSKBeaconManager: NSObject, CLLocationManagerDelegate {
    // nearspeak iBeacon UUID
    private let nearspeakUUIDString = "F7826DA6-4FA2-4E98-8024-BC5B71E0893E"
    private let nearspeakID = "Nearspeak iBeacon"
    private let locationManager = CLLocationManager()
    private var beaconRegion: CLBeaconRegion! = nil
    
    public var delegate: NSKBeaconManagerDelegate! = nil
    public var currentBeacons: [CLBeacon] = []
    
    public override init() {
        super.init()
        
        let beaconUUID = NSUUID(UUIDString: nearspeakUUIDString)
        beaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, identifier: nearspeakID)
        
        // notify only if the display is on
        beaconRegion.notifyEntryStateOnDisplay = true
        beaconRegion.notifyOnEntry = false
        beaconRegion.notifyOnExit = true
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        //locationManager.pausesLocationUpdatesAutomatically = false
    }

    public func startMonitoringForNearspeakBeacons() {
        locationManager.startMonitoringForRegion(beaconRegion)
    }
    
    public func stopMonitoringForNearspeakBeacons() {
        locationManager.stopRangingBeaconsInRegion(beaconRegion)
        locationManager.stopMonitoringForRegion(beaconRegion)
    }
    
    public func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        locationManager.requestStateForRegion(beaconRegion)
    }
    
    public func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
        switch state {
        case CLRegionState.Inside:
            locationManager.startRangingBeaconsInRegion(beaconRegion)
        default:
            locationManager.stopRangingBeaconsInRegion(beaconRegion)
        }
    }
    
    public func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        NSLog("DBG: %@", __FUNCTION__)
        locationManager.startRangingBeaconsInRegion(beaconRegion)
    }
    
    public func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        NSLog("DBG: %@", __FUNCTION__)
        locationManager.stopRangingBeaconsInRegion(beaconRegion)
        // reset current beacon
        currentBeacons = []
    }
    
    public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        //NSLog("DBG: %@", __FUNCTION__)
        
        if let beaconObjects = beacons as? [CLBeacon] {
            // empty the current array
            currentBeacons = []
            
            for beacon in beaconObjects {
                currentBeacons.append(beacon)
            }
            
            if let mydelegate = delegate {
                mydelegate.beaconManager(self, foundBeacons: currentBeacons)
            }
        }
    }
}