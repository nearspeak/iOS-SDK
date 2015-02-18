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
    // Kontakt.io: F7826DA6-4FA2-4E98-8024-BC5B71E0893E
    // Estimote:   B9407F30-F5F8-466E-AFF9-25556B57FE6D
    // Nearspeak:  CEFCC021-E45F-4520-A3AB-9D1EA22873AD
    // only 20 different UUIDs per App are supported by iOS
    private let nearspeakProximityUUIDs = [
        NSUUID(UUIDString:"CEFCC021-E45F-4520-A3AB-9D1EA22873AD")]
    
    private var rangedRegions: NSMutableDictionary = NSMutableDictionary()
    
    private let locationManager = CLLocationManager()
    
    public var delegate: NSKBeaconManagerDelegate! = nil
    
    public override init() {
        super.init()
        
        for uuid in nearspeakProximityUUIDs {
            if let currentUUID = uuid {
                var beaconRegion = CLBeaconRegion(proximityUUID: currentUUID, identifier: currentUUID.UUIDString)
                
                // notify only if the display is on
                beaconRegion.notifyEntryStateOnDisplay = true
                beaconRegion.notifyOnEntry = false
                beaconRegion.notifyOnExit = true
                
                self.rangedRegions[beaconRegion] = NSArray()
            }
        }
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    public func startRangingForNearspeakBeacons() {
        for beaconRegion in self.rangedRegions {
            locationManager.startRangingBeaconsInRegion(beaconRegion.key as CLBeaconRegion)
        }
    }
    
    public func stopRangingForNearspeakBeacons() {
        for beaconRegion in self.rangedRegions {
            locationManager.stopRangingBeaconsInRegion(beaconRegion.key as CLBeaconRegion)
        }
    }

    public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        self.rangedRegions[region] = beacons

        var allBeacons = NSMutableArray()
        
        for beaconsArray in self.rangedRegions.allValues {
            allBeacons.addObjectsFromArray(beaconsArray as NSArray)
        }
        
        if let mydelegate = delegate {
            mydelegate.beaconManager(self, foundBeacons: allBeacons as NSArray as [CLBeacon])
        }
    }
}