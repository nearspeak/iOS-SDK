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
import CoreBluetooth

/**
 Delegate protocol for the Nearspeak beacon manager class.
 */
public protocol NSKBeaconManagerDelegate {
    /** 
     This method informs, that there are new found beacons available.

     :param: manager The Nearspeak beacon manager object.
     :param: foundBeacons An array with CLBeacon objects.
     */
    func beaconManager(manager: NSKBeaconManager!, foundBeacons:[CLBeacon])
    
    /**
     This method informs, that there is bluetooth available or not.

    :param: manager The Nearspeak beacon manager object.
    :param: bluetoothState The CoreBluetoothManagerState object.
    */
    func beaconManager(manager: NSKBeaconManager!, bluetoothStateDidChange bluetoothState: CBCentralManagerState)
    
    /**
     This method informs, if there is a location available or not.

    :param: manager The Nearspeak beacon manager object.
    :param: locationState The CoreLocation CLAuthorizationStatus object.
    */
    func beaconManager(manager: NSKBeaconManager!, locationStateDidChange locationState: CLAuthorizationStatus)
}

/**
 The Nearspeak beacon manager class.
*/
public class NSKBeaconManager: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    // nearspeak iBeacon UUID
    // Kontakt.io:  F7826DA6-4FA2-4E98-8024-BC5B71E0893E
    // Estimote:    B9407F30-F5F8-466E-AFF9-25556B57FE6D
    // Nearspeak:   CEFCC021-E45F-4520-A3AB-9D1EA22873AD
    // Starnberger: 699EBC80-E1F3-11E3-9A0F-0CF3EE3BC012
    // only 20 different UUIDs per App are supported by iOS
    // TODO: get the UUIDS from the server
    private let nearspeakProximityUUIDs = [
        NSUUID(UUIDString:"CEFCC021-E45F-4520-A3AB-9D1EA22873AD"),
        NSUUID(UUIDString:"699EBC80-E1F3-11E3-9A0F-0CF3EE3BC012")
    ]
    
    private var nearspeakRegions: NSMutableDictionary = NSMutableDictionary()
    
    private let locationManager = CLLocationManager()
    private var centralManager = CBCentralManager()
    
    /** The delegate object of this class. */
    public var delegate: NSKBeaconManagerDelegate! = nil
    
    /**
     Initializer for this class.
    */
    public override init() {
        super.init()
        
        // init the bluetooth stuff
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
        
        for uuid in nearspeakProximityUUIDs {
            if let currentUUID = uuid {
                var beaconRegion = CLBeaconRegion(proximityUUID: currentUUID, identifier: currentUUID.UUIDString)
                
                // notify only if the display is on
                beaconRegion.notifyEntryStateOnDisplay = true
                beaconRegion.notifyOnEntry = false
                beaconRegion.notifyOnExit = true
                
                self.nearspeakRegions[beaconRegion] = NSArray()
            }
        }
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        checkForBeaconSupport()
    }
    
    /**
     Start monitoring for Nearspeak beacons.
    */
    public func startMonitoringForNearspeakBeacons() {
        for beaconRegion in self.nearspeakRegions {
            locationManager.startMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
     Stop monitoring for Nearspeak beacons.
    */
    public func stopMonitoringForNearspeakBeacons() {
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }

    /**
     Start ranging for Nearspeak beacons.
    */
    public func startRangingForNearspeakBeacons() {
        for beaconRegion in self.nearspeakRegions {
            locationManager.startRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
     Stop ranging for Nearspeak beacons.
    */
    public func stopRangingForNearspeakBeacons() {
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    private func checkForBeaconSupport() {
        if CLLocationManager.isRangingAvailable() {
            #if DEBUG
                println("Beacon support available")
            #endif
        } else {
                println("ERROR: Beacon support not available")
        }
    }

    // MARK: CoreLocationManager delegate methods
   
    /**
     Delegate method, which gets called if you access a new beacon region.
    */
    public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        self.nearspeakRegions[region] = beacons
        
        var allBeacons = NSMutableArray()
        
        for beaconsArray in self.nearspeakRegions.allValues {
            allBeacons.addObjectsFromArray(beaconsArray as! NSArray as [AnyObject])
        }
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, foundBeacons: allBeacons as NSArray as! [CLBeacon])
        }
    }
    
    /**
     Delegate method, which gets called if core location changes its authorization status.
    */
    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        #if DEBUG
            switch status {
            case .AuthorizedAlways:
                println("DBG: CoreLocation - Location incl. background support.")
            case .AuthorizedWhenInUse:
                println("DBG: CoreLocation - Location without background support.")
            case .Denied, .NotDetermined, .Restricted:
                println("DBG: CoreLocation - No Location support.")
            }
        #endif
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, locationStateDidChange: status)
        }
    }
    
    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("DBG: CoreLocation: didFailWithError: \(error.localizedDescription)")
    }
    
    public func centralManagerDidUpdateState(central: CBCentralManager!) {
        #if DEBUG
            switch central.state {
            case .PoweredOff:
                println("DBG: Bluetooth - Powered off")
            case .PoweredOn:
                println("DBG: Bluetooth - Powered on")
            case .Resetting:
                println("DBG: Bluetooth - Resetting")
            case .Unauthorized:
                println("DBG: Bluetooth - Unauthorized")
            case .Unknown:
                println("DBG: Bluetooth - Unknown")
            case .Unsupported:
                println("DBG: Bluetooth - Unsupported")
            }
        #endif
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, bluetoothStateDidChange: central.state)
        }
    }
}