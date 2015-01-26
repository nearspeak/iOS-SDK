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
     func beaconManager(manager: NSKBeaconManager!, foundBeaconWithUUID uuid: NSUUID!, withMajor major: NSNumber, andMinor minor: NSNumber)
}

public class NSKBeaconManager: NSObject, CLLocationManagerDelegate {
    // nearspeak iBeacon UUID
    let nearspeakUUIDString = "F7826DA6-4FA2-4E98-8024-BC5B71E0893E"
    let nearspeakID = "Nearspeak iBeacon"
    let locationManager = CLLocationManager()
    var beaconRegion: CLBeaconRegion! = nil
    public var delegate:NSKBeaconManagerDelegate! = nil
    var currentBeacon: CLBeacon! = nil
    
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
        //NSLog("DBG: %@", __FUNCTION__)
        locationManager.startRangingBeaconsInRegion(beaconRegion)
    }
    
    public func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        //NSLog("DBG: %@", __FUNCTION__)
        locationManager.stopRangingBeaconsInRegion(beaconRegion)
        // reset current beacon
        currentBeacon = nil
    }
    
    public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        if (beacons.count > 0) {
            let nearestBeacon = beacons.first as CLBeacon
            
            if (!isCurrentBeacon(nearestBeacon)) {
                currentBeacon = nearestBeacon
                
                if let mydelegate = delegate {
                    mydelegate.beaconManager(self, foundBeaconWithUUID: currentBeacon.proximityUUID, withMajor: currentBeacon.major, andMinor: currentBeacon.minor)
                }
            }
        }
    }
    
    private func isCurrentBeacon(newBeacon: CLBeacon) -> Bool {
        if(currentBeacon == nil) {
            return false
        }
        
        if (currentBeacon.proximityUUID.UUIDString == newBeacon.proximityUUID.UUIDString) {
            if (currentBeacon.major == newBeacon.major) {
                if (currentBeacon.minor == currentBeacon.minor) {
                    return true
                }
            }
        }
        
        return false
    }
}