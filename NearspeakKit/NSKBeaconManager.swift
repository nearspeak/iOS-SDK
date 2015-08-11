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
public class NSKBeaconManager: NSObject {
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
    }
    
    /**
     Start monitoring for Nearspeak beacons.
    */
    public func startMonitoringForNearspeakBeacons() {
        #if DEBUG
            println("DBG: start monitoring for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
     Stop monitoring for Nearspeak beacons.
    */
    public func stopMonitoringForNearspeakBeacons() {
        #if DEBUG
            println("DBG: stop monitoring for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }

    /**
     Start ranging for Nearspeak beacons.
    */
    public func startRangingForNearspeakBeacons() {
        #if DEBUG
            println("DBG: start ranging for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
     Stop ranging for Nearspeak beacons.
    */
    public func stopRangingForNearspeakBeacons() {
        #if DEBUG
            println("DBG: stop ranging for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
     Check if beacon support is enabled.
    
     :return: Return true if all necessary features are enabled, otherwise false.
    */
    public func checkForBeaconSupport() -> Bool {
        if CLLocationManager.isRangingAvailable() {
            #if DEBUG
                println("Beacon ranging support available")
            #endif
        } else {
            println("ERROR: Beacon ranging support not available")
            
            return false
        }
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
            println("ERROR: Can't always get the location")
            
            return false
        }
        
        if centralManager.state == CBCentralManagerState.PoweredOff {
            println("ERROR: Problems with bluetooth")
            
            return false
        }
        
        return true
    }
}

// MARK: - CLLocationManagerDelegate
extension NSKBeaconManager: CLLocationManagerDelegate {
    
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
                println("DBG: CoreLocation - Location including background support.")
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
    
    /**
    Delegate method, which gets called if core location manager fails.
    */
    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("DBG: CoreLocation: didFailWithError: \(error.localizedDescription)")
    }
    
    /**
    * Delegate method, which gets called if you enter a defined region.
    */
    public func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        #if DEBUG
            println("DBG: didEnterRegion")
        #endif
    }
    
    /**
    * Delegate method, which gets called if you exit a defined region.
    */
    public func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        #if DEBUG
            println("DBG: didExitRegion")
        #endif
    }
    
    /**
    * Delegate method, which gets called if monitoring failed for a region.
    */
    public func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        #if DEBUG
            println("DBG: monitoring failed for region")
        #endif
    }
}

// MARK: - CBCentralManagerDelegate
extension NSKBeaconManager: CBCentralManagerDelegate {
    
    /**
    Delegate method, which gets called if core bluetooth manager changes its state.
    */
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